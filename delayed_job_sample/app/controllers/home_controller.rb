class HomeController < ApplicationController
  def hello
    Hello.delay.say_hello(params[:message])
    render :text => params[:message]
  end
end
