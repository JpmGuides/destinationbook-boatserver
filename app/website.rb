require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'

require_relative 'models/guide'

require File.expand_path('../../config/application', __FILE__)

configure {
  set :server, :puma
}

module Application
  # @api public
  # The endpoint where the guide are accessible
  class Website < Sinatra::Base
    set :static, true
    set :public_folder, File.expand_path('../../public', __FILE__)

    before do
      content_type :json
      headers  'Access-Control-Allow-Origin' => '*',
              'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
              'Cache-Control' => 'no-cache, no-store, must-revalidate',
              'Pragma' => 'no-cache',
              'Expires' => '0'
    end

    # @api public
    # List  available trips
    #
    # example reponse:
    #   {
    #     "trips": [
    #       {
    #         "name": "EUX1811",
    #         "description": "Abu Dhab - Dubai",
    #         "start_date": "2018-05-13",
    #         "end_date": "2018-05-22",
    #         "language": "de",
    #         "updated_at": "2018-04-03T07:59:08.780Z",
    #         "type": "trip",
    #         "image": "",
    #         "bookings": [
    #           {
    #             "username": "GUEST",
    #             "authentication_token": "HLKFEUX1811-DE",
    #             "updated_at": "2017-05-12T09:08:54.958Z"
    #            }
    #          ],
    #          "guides": [
    #            {
    #              "id": "2044.02",
    #              "url": "...",
    #              "generated_at": "2017-11-21T09:00:22.000+00:00",
    #              "name": "Katar",
    #              "description": "Miniguide",
    #              "size": 1102519,
    #              "language": "de"
    #            },
    #            {
    #              "id": "2045.02",
    #              "url": "...",
    #              "generated_at": "2017-11-21T09:00:35.000+00:00",
    #              "name": "Bahrain",
    #              "description": "Miniguide",
    #              "size": 2164075,
    #              "language": "de"
    #            }
    #          ]
    #        },
    #        ...
    #      ]
    #    }
    #
    # @note be carefule, guide url in this response are the url to the destinationbook storage, the links are valid for 30 minutes. they must not be used.
    get '/trips' do
      File.read('public/trips.json')
    end

    # @api public
    # List available guides
    #
    # example response:
    #   [
    #     {
    #       'id': '1507.00',
    #       'path': 'guides/1507.00'
    #       'updated_at': '2018-05-17 16:57:47 +0200'
    #     },
    #     ...
    #   ]
    get '/guides' do
      Guide.all.to_json
    end

    # @api public
    # The content of a guide
    #
    # example response:
    #    {
    #      "id": "1507.00",
    #      "titleImage": "images/03821-USA_East_capitole__thumb.jpg",
    #      "description": "Miniguide",
    #      "title": "Washington, D.C.",
    #      "headerImage": "images/03821-USA_East_capitole.jpg",
    #      "children": [
    #        {
    #          "children": [
    #            {
    #              "children": [],
    #              "linkTarget": null,
    #              "link": {
    #                "target": null,
    #                "options": {
    #                  "markGeo": null
    #                }
    #              },
    #              "linkAnchors": [
    #                "144553"
    #              ],
    #             "title": "17th century",
    #             "content": "<p>html tagged content <img src=\"images/10543-USA_East_pocahontas.jpg\" title=\"Jamestown remembers the Indian chief’s daughter Pocahontas.\"><span class=\"legend\">Jamestown remembers the Indian chief’s daughter Pocahontas.</span></div>"
    #           },
    #           {
    #             "children": [],
    #             "linkTarget": null,
    #             "link": {
    #               "target": null,
    #               "options": {
    #                 "markGeo": null
    #               }
    #             },
    #             "linkAnchors": [
    #               "144554"
    #             ],
    #             "title": "18th century",
    #             "content": "<p>html tagged content</p>"
    #           }
    #         ],
    #       "linkTarget": null,
    #       "link": {
    #       "target": null,
    #           "options": {
    #             "markGeo": null
    #           }
    #         },
    #         "linkAnchors": [
    #           "144552"
    #         ],
    #         "title": "A Brief History",
    #         "headerImageLegend": "The Legend of the image.",
    #         "headerImage": "images/10511-USA_East_timbre.jpg"
    #       },
    #     ],
    #     "images": [
    #       {
    #         "path": "images/03821-USA_East_capitole.jpg""
    #       },
    #       {
    #         "path": "images/10543-USA_East_pocahontas.jpg"
    #       },
    #       {
    #         "path": "images/10511-USA_East_timbre.jpg"
    #       }
    #     ]
    #   }
    #
    # - "children" keys represent chapter, the include other chapters recursively
    # - "images" key include all the image used in guide, images may exists in a thumb version (with __thumb after filename)
    # - all link to images are relative to guide path
    get '/guides/:guide_id' do
      puts params['guide_id']
      Guide.new(params['guide_id']).content
    rescue GuideNotFound => e
      halt 404, 'guide not found'
    end

    # @api public
    # Files relative to a guides
    #
    # for example:
    #    /guides/1507.01/images/10511-USA_East_timbre.jpg
    get '/guides/:guide_id/:type/:file' do
      guide = Guide.new(params['guide_id'])

      content_type File.extname(params['file'])

      send_file File.join(guide.web_path, params['type'], params['file'])
    rescue GuideNotFound => e
      halt 404, 'guide not found'
    end

    # @api private
    get '/last_update' do
      {time: File.mtime('public/trips.json')}.to_json
    end

    # @api private
    get '/export' do
      format_params
      save_connections

      begin
        File.read("public/wallets/#{params['username']}_#{params['authentication_token']}.json")
      rescue => e
        halt 404, e.inspect
      end
    end

    run! if app_file == $0

    protected

    def format_params
      params['mobile_app'] ||= {}
      params['device'] ||= {}
      if params['version']
        params['mobile_app']['version'] = params['version']
      end

      params.reject { |k, v| v.nil? || v.empty? }
      params['device'].merge(params['mobile_app'].inject({}) {|hash, values| hash["mobile_app_#{values.first}"] = values.last; hash })

      params['username']             = params['username'].to_s.gsub(/\s/, '').upcase
      params['authentication_token'] = params['authentication_token'].to_s.gsub(/\s/, '').upcase
    end

    def save_connections
      path = File.expand_path('public/connections.json')

      File.open(path, 'a') do |file|
        file.write "#{params.to_json}, "
      end
    end

    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
  end
end
