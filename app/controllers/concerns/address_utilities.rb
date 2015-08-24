module AddressUtilities
  extend ActiveSupport::Concern

  included do
    before_action :ensure_address_and_graetzl, only: [:new]
  end

  # def get_address(callback)
  #   if request.post? && address_params[:address]
  #     address = Address.new(Address.attributes_from_feature(address_params[:feature] || ''))
  #     puts 'SETTING ADDRESS'
  #     session[:address] = address.attributes
  #     callback.call(address)
  #   else
  #     false
  #   end
  # end

  def empty_session
    puts 'EMPTY SESSION'
    session.delete(:address)
    session.delete(:graetzl)
  end

  private

    def ensure_address_and_graetzl
      unless(session[:address] || address_params[:address])
        render :address_form
      else
        set_address_and_graetzl if (request.post? && address_params[:address])
      end        
    end

    def set_address_and_graetzl
      puts 'SETTING ADDRESS AND GRAETZL (IN SESSION)'
      @address = Address.new(Address.attributes_from_feature(address_params[:feature] || ''))
      session[:address] = @address.attributes
      @graetzl = @address.graetzl || current_user.graetzl
      session[:graetzl] = @graetzl.id
    end

    # strong params for address
    def address_params
      params.permit(:address, :feature)
    end
end