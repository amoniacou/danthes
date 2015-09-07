require 'spec_helper'
require 'danthes/view_helpers'

module Danthes
  describe ViewHelpers do

    let(:klass) do
      Class.new do
        include ActionView::Helpers::TagHelper
        include ActionView::Context
        include ViewHelpers
      end
    end

    describe '#subscribe_to' do
      it "generates javascript tag by default" do
        expect(klass.new.subscribe_to('hello')).to match /\A<script.*<\/script>\z/
      end

      it "removes javascript tag when *include_js_tag* is set to false" do
        expect(klass.new.subscribe_to('hello', include_js_tag: false)).to match /\Aif \(typeof Danthes \!= 'undefined'\) { Danthes.sign\(.*\) }\z/
      end
    end

  end
end
