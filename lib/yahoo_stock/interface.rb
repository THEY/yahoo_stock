=begin

http://www.gummy-stuff.org/Yahoo-data.htm
http://finance.yahoo.com/d/quotes.csv?s=XOM+BBDb.TO+JNJ+MSFT&f=snd1l1yr

=end

=begin

Class to generate the right url and interface with yahoo

=end

require 'net/http'
module YahooStock
  class Interface
    
    class InterfaceError < RuntimeError ; end
      
    PARAMETERS = {
      :ask => 'a',
      :average_daily_volume => 'a2',
      :ask_size => 'a5',
      :bid => 'b',
      :ask_real_time => 'b2',
      :bid_real_time => 'b3',
      :book_value => 'b4',
      :bid_size => 'b4',
      :change_with_percent_change => 'c',
      :change => 'c1',
      :commission => 'c3',
      :change_real_time => 'c6',
      :after_hours_change_real_time => 'c8',
      :dividend_per_share => 'd',
      :last_trade_date => 'd1',
      :trade_date => 'd2',
      :earnings_per_share => 'e',
      :error_indication => 'e1',
      :eps_estimate_current_year => 'e7',
      :eps_estimate_next_year => 'e8',
      :eps_estimate_next_quarter => 'e9',
      :day_low => 'g',
      :day_high => 'h',
      :fifty_two_week_low => 'j',
      :fifty_two_week_high => 'k',
      :holdings_gain_percent => 'g1',
      :annualized_gain => 'g3',
      :holdings_gain => 'g4',
      :holdings_gain_percent_real_time => 'g5',
      :holdings_gain_real_time => 'g6',
      :more_info => 'i',
      :order_book_real_time => 'i5',
      :market_capitalization => 'j1',
      :market_cap_real_time => 'j3',
      :ebitda => 'j4',
      :change_from_52_week_low => 'j5',
      :percent_change_from_52_week_low => 'j6',
      :last_trade_real_time_with_time => 'k1',
      :change_percent_real_time => 'k2',
      :change_from_52_week_high => 'k4',
      :percent_change_from_52_week_high => 'k5',
      :last_trade_with_time => 'l',
      :last_trade_price_only => 'l1',
      :high_limit => 'l2',
      :low_limit => 'l3',
      :day_range => 'm',
      :day_range_real_time => 'm2',
      :fifty_day_moving_average => 'm3',
      :two_hundred_day_moving_average => 'm4',
      :change_from_200_day_moving_average => 'm5',
      :percent_change_from_200_day_moving_average => 'm6',
      :change_from_50_day_moving_average => 'm7',
      :percent_change_from_50_day_moving_average => 'm8',
      :name => 'n',
      :notes => 'n4',
      :open => 'o',
      :previous_close => 'p',
      :price_paid => 'p1',
      :change_in_percent => 'p2',
      :ex_dividend_date => 'q',
      :p_e_ratio => 'r',
      :dividend_pay_date => 'r1',
      :p_e_ratio_real_time => 'r2',
      :peg_ratio => 'r5',
      :price_eps_estimate_current_year => 'r6',
      :price_eps_estimate_next_year => 'r7',
      :symbol => 's',
      :shares_owned => 's1',
      :short_ratio => 's7',
      :last_trade_time => 't1',
      :trade_links => 't6',
      :ticker_trend => 't7',
      :one_yr_target_price => 't8',
      :volume => 'v',
      :holdings_value => 'v1',
      :holdings_value_real_time => 'v7',
      :fifty_two_week_range => 'w',
      :day_value_change => 'w1',
      :day_value_change_real_time => 'w4',
      :stock_exchange => 'x',
      :dividend_yield => 'y',
    }
    
    attr_accessor :stock_symbols, :yahoo_url_parameters
    
    def initialize(stock_params_hash)
      unless stock_params_hash
        raise InterfaceError, 'You must pass a hash of stock symbols and the data you would like to see' 
      end
      if !stock_params_hash[:stock_symbols]  || stock_params_hash[:stock_symbols].length.zero?
        raise(InterfaceError, 'No stocks passed')
      end
      if !stock_params_hash[:read_parameters] || stock_params_hash[:read_parameters].length.zero?
        raise InterfaceError, 'Dont know what data to get'
      end
      @stock_symbols = stock_params_hash[:stock_symbols]
      @yahoo_url_parameters    = stock_params_hash[:read_parameters]
      @base_url      = "http://download.finance.yahoo.com/d/quotes.csv"
    end
    
    def full_url
      all_stock_symbols = stock_symbols.join('+')
      parameter_values  = yahoo_url_parameters.collect {|v| parameters[v]}.join('')
      if !all_stock_symbols.any?  
        raise InterfaceError, "You must add atleast one stock symbol to get stock data" 
      end
      if !parameter_values.any?
        raise InterfaceError, "You must add atleast one parameter to get stock data" 
      end
      "#{@base_url}?s=#{all_stock_symbols}&f=#{parameter_values}"
    end
    
    def get_values
      Net::HTTP.get(URI.parse(full_url)).gsub(/\"/,'').split(/\r\n/)
    end
    
    def results
      stock = {}
      get_values.each_with_index do |values, index|
        parsed_values = values.split(',')
        stock[stock_symbols[index]] ||= {}
        parsed_values.each_with_index do |value, i|
          stock[stock_symbols[index]][yahoo_url_parameters[i]] = value
        end
      end
      stock
    end
    
    def add_symbols(*symbols)
      symbols.each do |symbol|
        unless stock_symbols.include?(symbol)
          stock_symbols << symbol
        end
      end
    end
    
    def remove_symbols(*symbols)
      symbols.each do |symbol|
        unless stock_symbols.include?(symbol)
          raise InterfaceError, "Cannot remove stock symbol #{symbol} as it is currently not present."
        end
        stock_symbols.reject!{|stock_sym| stock_sym == symbol}
      end
    end
    
    def add_parameters(*parameters)
      parameters.each do |parameter|
        unless allowed_parameters.include?(parameter)
          raise InterfaceError, "Interface parameter #{parameter} is not a valid parameter."
        end
        unless yahoo_url_parameters.include?(parameter)
          yahoo_url_parameters << parameter
        end
      end
    end
    
    def remove_parameters(*parameters)
      parameters.each do |parameter|
        unless yahoo_url_parameters.include?(parameter)
          raise InterfaceError, "Parameter #{parameter} is not present in current list"
        end
        yahoo_url_parameters.reject!{|parameter_key| parameter_key == parameter}
      end
    end
    
    def allowed_parameters
      parameters.keys
    end
    
    private
    
    def parameters
      PARAMETERS
    end
    
  end
end
