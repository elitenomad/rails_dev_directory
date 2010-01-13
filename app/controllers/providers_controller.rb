class ProvidersController < ApplicationController
  
  ssl_required :new, :create

  def index
    @providers = Provider.active.all_by_company_name.paginate(:page => params[:page])
  end
  
  def by_location
    @providers = Provider.active.all_by_location
  end
  
  def search
    @top_services = Service.priority(1).reject_category(@general_category)
    @providers = Provider.search(params)
    respond_to do |wants|
      wants.html
      wants.json { render :json => {
        :providers => render_to_string(:partial => 'provider.html', :collection => @providers),
        :pagination => render_to_string(:partial => 'pagination.html')
        }
      }
    end
  end
  
  def show
    @provider = Provider.find(params[:id])
    @provider.increment!(:views) unless logged_in? and current_user.provider == @provider
  end
  
  def new
    @provider = Provider.new
  end

  def create
    @provider = Provider.new(params[:provider])
    @provider.users.first.password = params['provider']['users_attributes']['0']['password']
    @provider.users.first.password_confirmation = params['provider']['users_attributes']['0']['password_confirmation']
    @page_content = Page.find_by_url('provider-signup')
    if verify_recaptcha(:model => @provider) && @provider.save
      @provider.update_attribute(:slug, @provider.user.slugged_name) if @provider.slug[0,7] == 'unnamed'
      @provider = @provider.reload
      @provider.update_attribute(:user, @provider.users.first)
      UserSession.create(@provider.user)
      Notification.deliver_provider_welcome(@provider.user)
      redirect_to my_dashboard_url
    else
      render :new
    end
  end

end