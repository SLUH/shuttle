# Copyright 2013 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require 'spec_helper'

describe SearchController do
  include Devise::TestHelpers

  describe '#translations' do
    before :all do
      @user = FactoryGirl.create(:user, role: 'translator')

      %w(term1 term2).each do |term|
        %w(source_copy copy).each do |field|
          other_field        = (field == 'copy' ? 'source_copy' : 'copy')
          locale_field       = (field == 'copy' ? :rfc5646_locale : :source_rfc5646_locale)
          other_locale_field = (field == 'copy' ? :source_rfc5646_locale : :rfc5646_locale)
          %w(en fr).each do |locale|
            other_locale = (locale == 'en' ? 'fr' : 'en')
            FactoryGirl.create :translation,
                               field              => "foo #{term} bar",
                               other_field        => 'something else',
                               locale_field       => locale,
                               other_locale_field => other_locale
          end
        end
      end
    end

    before :each do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in @user
    end

    it "should return an empty result list if no query is given" do
      get :translations, query: ' ', format: 'json'
      response.status.should eql(200)
      response.body.should eql('[]')
    end

    it "should search the copy field by default" do
      get :translations, query: 'term1', format: 'json'
      response.status.should eql(200)
      results = JSON.parse(response.body)
      results.size.should eql(2)
      results.each { |r| r['copy'].should eql('foo term1 bar') }
    end

    it "should search the source_copy field" do
      get :translations, query: 'term1', field: 'searchable_source_copy', format: 'json'
      response.status.should eql(200)
      results = JSON.parse(response.body)
      results.size.should eql(2)
      results.each { |r| r['source_copy'].should eql('foo term1 bar') }
    end

    it "should filter by target locale" do
      get :translations, query: 'term1', target_locales: 'fr', format: 'json'
      response.status.should eql(200)
      results = JSON.parse(response.body)
      results.size.should eql(1)
      results.first['copy'].should eql('foo term1 bar')
      results.first['locale']['rfc5646'].should eql('fr')
    end

    it "should respond with a 422 if the locale is unknown" do
      get :translations, query: 'term1', target_locales: 'fr, foobar?', format: 'json'
      response.status.should eql(422)
      response.body.should be_blank
    end

    it "should accept a limit and offset" do
      get :translations, query: 'term1', offset: 0, limit: 1, format: 'json'
      response.status.should eql(200)
      results1 = JSON.parse(response.body)
      results1.size.should eql(1)

      get :translations, query: 'term1', offset: 1, limit: 1, format: 'json'
      response.status.should eql(200)
      results2 = JSON.parse(response.body)
      results2.size.should eql(1)

      results1.first['id'].should_not eql(results2.first['id'])
    end
  end

  describe '#keys' do
    before :all do
      @user    = FactoryGirl.create(:user, role: 'translator')
      @project = FactoryGirl.create(:project)

      5.times { |i| FactoryGirl.create :key, project: @project, key: "term1_number#{i}" }
      5.times { |i| FactoryGirl.create :key, project: @project, key: "term2_number#{i}" }
    end

    before :each do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in @user
    end

    it "should return an empty result list if no query is given" do
      get :keys, keys: ' ', project_id: @project.id, format: 'json'
      response.status.should eql(200)
      response.body.should eql('[]')
    end

    it "should search by key" do
      get :keys, filter: 'term1', project_id: @project.id, format: 'json'
      response.status.should eql(200)
      results = JSON.parse(response.body)
      results.size.should eql(5)
      results.map { |r| r['original_key'] }.sort.should eql(%w(term1_number0 term1_number1 term1_number2 term1_number3 term1_number4))
    end

    it "should respond with a 422 if the project ID is not given" do
      get :keys, filter: 'term1', format: 'json'
      response.status.should eql(422)
      response.body.should be_blank
    end

    it "should accept a limit and offset" do
      get :keys, filter: 'term1', project_id: @project.id, offset: 0, limit: 1, format: 'json'
      response.status.should eql(200)
      results1 = JSON.parse(response.body)
      results1.size.should eql(1)

      get :keys, filter: 'term1', project_id: @project.id, offset: 1, limit: 1, format: 'json'
      response.status.should eql(200)
      results2 = JSON.parse(response.body)
      results2.size.should eql(1)

      results1.first['id'].should_not eql(results2.first['id'])
    end
  end
end
