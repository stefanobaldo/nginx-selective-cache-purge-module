require "spec_helper"

describe "Selective Cache Purge Module Database Lock" do
  let!(:database_file) { File.join "/", "tmp", "cache.db" }
  let!(:config) { NginxConfiguration.default_configuration.merge worker_processes: 4, database_file: database_file, purge_query: "$1%"}

  let(:db) { SQLite3::Database.new database_file }

  before :each do
    File.unlink database_file if File.exists? database_file
  end

  def run_concurrent_requests_check(number_of_requests, path = "", &block)
    requests_sent = 0
    EventMachine.run do
      cached_requests_timer = EventMachine::PeriodicTimer.new(0.001) do
        requests_sent += 1
        current_req_num = requests_sent
        if current_req_num > number_of_requests
          cached_requests_timer.cancel
          if block.nil?
            EventMachine.stop
          else
            EventMachine.add_timer(0.5) do
              yield
              EventMachine.stop
            end
          end
        else
          req = EventMachine::HttpRequest.new("http://#{nginx_host}:#{nginx_port}#{path}/#{current_req_num}/index.html", connect_timeout: 10, inactivity_timeout: 15).get
          req.callback do
            fail("Request failed with error #{req.response_header.status}") if req.response_header.status != 200
          end
          req.errback do
            fail("Deu cagada!!! #{req.error}")
            EventMachine.stop
          end
        end
      end
    end
  end

  context "serializing database writes" do
    it "should not lose requests when inserting cache entries into database" do
      nginx_run_server(config, timeout: 200) do
        number_of_requests = 2000
        run_concurrent_requests_check(number_of_requests) do
          db.execute("select count(*) from selective_cache_purge").first.should eql [number_of_requests]
        end
      end
    end

    it "should not lose requests when deleting cache entries from database" do
      nginx_run_server(config, timeout: 200) do
        number_of_requests = 2000
        run_concurrent_requests_check(number_of_requests) do
          run_concurrent_requests_check(number_of_requests, "/purge") do
            db.execute("select count(*) from selective_cache_purge").first.should eql [0]
          end
        end
      end
    end
  end
end