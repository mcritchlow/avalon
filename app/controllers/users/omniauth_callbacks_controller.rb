# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # The default OmniAuth forms don't provide CSRF tokens, so we can't verify
  # them. Trying to verify results in a cleared session.
  skip_before_action :verify_authenticity_token

  def passthru
    begin
      render "modules/#{params[:provider]}_auth_form"
    rescue ActionView::MissingTemplate
      redirect_to new_user_session_path, flash: { alert: I18n.t('devise.failure.invalid') }
    end
  end

  def after_omniauth_failure_path_for(scope)
    case failed_strategy.name
    when 'lti'
      default_msg = I18n.t 'devise.omniauth_callbacks.failure', reason: failure_message
      msg = I18n.t 'devise.omniauth_callbacks.lti.failure', default: default_msg
      uri = URI.parse request['launch_presentation_return_url']
      uri.query = {lti_errormsg: msg}.to_query
      uri.to_s
    else
      new_user_session_path(scope)
    end
  end

  def action_missing(sym, *args, &block)
    logger.debug "Attempting to find user with #{sym.to_s} strategy"
    find_user(sym.to_s)
  end

  def find_user(auth_type)
    auth_type.downcase!
    find_method = "find_for_#{auth_type}".to_sym
    find_method = :find_for_generic unless User.respond_to?(find_method)
    logger.debug "#{auth_type} :: #{current_user.inspect}"
    @user = User.send(find_method,request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:success] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in @user, :event => :authentication
      user_session[:virtual_groups] = @user.ldap_groups
      user_session[:full_login] = true

      if auth_type == 'lti'
        user_session[:lti_group] = request.env["omniauth.auth"].extra.context_id
        user_session[:virtual_groups] += [user_session[:lti_group]]
        user_session[:full_login] = false
      end

    end

    if params['login_popup'].present? || (request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?)
      flash[:success] = nil
      render inline: '<html><head><script>window.close();</script></head><body></body><html>'.html_safe
    elsif params['target_id']
      # Whitelist params that are allowed to be passed through via LTI
      params_whitelist = %w{t position token}
      redirect_to objects_path(params['target_id'], params.permit(*params_whitelist).to_h)
    elsif params[:url]
      # Limit redirects to current host only
      # Fixes bug https://bugs.dlib.indiana.edu/browse/VOV-5662
      uri = URI.parse(params[:url])
      if request.host == uri.host
        redirect_to uri.path
      else
        redirect_to root_path
      end
    elsif session[:previous_url]
      redirect_to session.delete :previous_url
    elsif auth_type == 'lti' && user_session[:virtual_groups].present?
      redirect_to search_catalog_path('f[read_access_virtual_group_ssim][]' => user_session[:lti_group])
    else
      redirect_to root_path
    end
  end

  protected :find_user

  rescue_from Avalon::MissingUserId do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.lti_auth_error') % [support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end
end
