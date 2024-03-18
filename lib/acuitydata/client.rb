module AcuityData
  class Client
    include ::AcuityData::Constants

    attr_reader :auth_token, :base_path, :port

    def initialize(auth_token, base_path: BASE_PATH, port: BASE_PORT)
      @base_path = base_path
      @port = port
      @auth_token = auth_token
    end

    def self.compatible_api_version
      'v1'
    end

    # This is the version of the API docs this client was built off-of
    def self.api_version
      'v1 2024-03-19'
    end

    # Endpoints
    # /lookup/make
    # Retrieve make information
    def make
      send_request(http_method: :get, path: "lookup/make")
    end

    # /lookup/model/{make}
    # Retrieve model information for make
    def model(make, year = nil)
      if year
        send_request(http_method: :get, path: "lookup/model2/#{make}/#{year}")
      else
        send_request(http_method: :get, path: "lookup/model/#{make}")
      end
    end

    # /lookup/year/{make}/{model}
    # Retrieve year information for make and model
    def year(make, model = nil)
      if model
        send_request(http_method: :get, path: "lookup/year/#{make}/#{model}")
      else
        send_request(http_method: :get, path: "lookup/year2/#{make}")
      end
    end

    # /lookup/variant/{make}/{model}/{year}
    # Retrieve variant information for make, model and year
    def variant(make, model, year)
      send_request(http_method: :get, path: "lookup/variant/#{make}/#{model}/#{year}")
    end

    # /report/{make}/{model}/{variant}/{year}/{mileage}
    # Retrieve vehicle report using make, model, year, variant and mileage
    def report(make, model, variant, year, mileage)
      send_request(http_method: :get, path: "report/#{make}/#{model}/#{variant}/#{year}/#{mileage}")
    end

    private

    def send_request(http_method:, path:, body: {}, params: {}, headers: {}, port: @port, port_in_path: false)
      start_time = micro_second_time

      response = HTTParty.send(
        http_method.to_sym,
        construct_base_path(path, params, port, port_in_path),
        body: body,
        headers: headers.merge({ 'Content-Type': 'application/json', 'Authorization': "Basic #{@auth_token}" }),
        port: port,
        format: :json
      )

      end_time = micro_second_time
      construct_response_object(response, path, start_time, end_time)
    end

    # Quick n dirty time parsing
    def parse_time(str_time)
      time_components = str_time.to_s.split(' ')

      # Have to leave out the timezone - #{time_components[2]}
      "#{time_components[0]}T#{time_components[1]}"
    end

    def construct_response_object(response, path, start_time, end_time)
      {
        'body' => parse_body(response, path),
        'code' => response.code,
        'cookies' => response.headers.dig('set-cookie'),
        'headers' => response.headers,
        'metadata' => construct_metadata(response, start_time, end_time)
      }
    end

    def construct_metadata(response, start_time, end_time)
      total_time = end_time - start_time

      {
        'start_time' => start_time,
        'end_time' => end_time,
        'total_time' => total_time
      }
    end

    def micro_second_time
      (Time.now.to_f * 1_000_000).to_i
    end

    def construct_base_path(path, params, port, port_in_path)
      if port_in_path
        constructed_path = "#{base_path}:#{port}/#{path}"
      else
        constructed_path = "#{base_path}/#{path}"
      end

      if params == {}
        constructed_path.gsub(" ", "%20")
      else
        "#{constructed_path}?#{process_params(params)}".gsub(" ", "%20")
      end
    end

    def parse_body(response, path)
      JSON.parse(response.body) # Purposely not using HTTParty
    rescue JSON::ParserError => _e
      response.body
    rescue TypeError => _e
      nil
    end

    def process_params(params)
      params.keys.map { |key| "#{key}=#{params[key]}" }.join('&')
    end
  end
end
