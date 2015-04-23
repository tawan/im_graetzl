class Address < ActiveRecord::Base
  # associations
  belongs_to :addressable, polymorphic: true

  # validations
  validates :coordinates, presence: true
  validates :street_name, presence: true
  validates :city, presence: true

  # class methods

  # maybe put into service object later...
  def self.get_address_from_api(address_string)
    response = query_address_service(address_string)
    if !response.blank? && response.body.present?
      return Address.new_from_geojson(response['features'][0])
    end
    Address.new()
  end

  def self.parse_feature(feature)
    begin
      data = JSON.parse(feature)
      #puts JSON.pretty_generate(feature)
      Address.new_from_geojson(data)
    rescue JSON::ParserError => e
      # blahblah
      puts "json ran into parser error, return empty address"
      Address.new
    end
  end

  def self.new_from_geojson(feature)
    point = RGeo::GeoJSON.decode(feature['geometry'], :json_parser => :json)
    Address.new(
      coordinates: point,
      street_name: feature['properties']['StreetName'],
      street_number: feature['properties']['StreetNumber'],
      zip: feature['properties']['PostalCode'],
      city: feature['properties']['Municipality'])    
  end

  # instance methods
  def match_graetzls
    graetzls = Graetzl.where('ST_CONTAINS(area, :point)', point: coordinates)
    if graetzls.empty?
      graetzls = Graetzl.all
    end
    graetzls
  end

  private

    def self.query_address_service(address_string)
      query = "http://data.wien.gv.at/daten/OGDAddressService.svc/GetAddressInfo?Address=#{address_string}&crs=EPSG:4326"
      uri = URI.parse(URI.encode(query))
      begin
        HTTParty.get(uri)
      rescue
        nil
      end
    end

end
