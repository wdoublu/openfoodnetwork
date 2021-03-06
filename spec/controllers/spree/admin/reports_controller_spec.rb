require 'spec_helper'

describe Spree::Admin::ReportsController do
  
  # Given two distributors and two suppliers
  let(:ba) { create(:address) }
  let(:si) { "pick up on thursday please" }
  let(:s1) { create(:supplier_enterprise, address: create(:address)) }
  let(:s2) { create(:supplier_enterprise, address: create(:address)) }
  let(:s3) { create(:supplier_enterprise, address: create(:address)) }
  let(:d1) { create(:distributor_enterprise, address: create(:address)) }
  let(:d2) { create(:distributor_enterprise, address: create(:address)) }
  let(:d3) { create(:distributor_enterprise, address: create(:address)) }
  let(:p1) { create(:product, price: 12.34, distributors: [d1], supplier: s1) }
  let(:p2) { create(:product, price: 23.45, distributors: [d2], supplier: s2) }
  let(:p3) { create(:product, price: 34.56, distributors: [d3], supplier: s3) }

  # Given two order cycles with both distributors
  let(:ocA) { create(:simple_order_cycle, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p1.master, p3.master]) }
  let(:ocB) { create(:simple_order_cycle, distributors: [d1, d2], suppliers: [s1, s2, s3], variants: [p2.master]) }

  # orderA1 can only be accessed by s1, s3 and d1
  let!(:orderA1) do
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderA2 can only be accessed by s2 and d2
  let!(:orderA2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocA)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  # orderB1 can only be accessed by s1, s3 and d1
  let!(:orderB1) do
    order = create(:order, distributor: d1, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p1.master)
    order.line_items << create(:line_item, variant: p3.master)
    order.finalize!
    order.save
    order
  end
  # orderB2 can only be accessed by s2 and d2
  let!(:orderB2) do
    order = create(:order, distributor: d2, bill_address: ba, special_instructions: si, order_cycle: ocB)
    order.line_items << create(:line_item, variant: p2.master)
    order.finalize!
    order.save
    order
  end
  
  # As a Distributor Enterprise user for d1  
  context "Distributor Enterprise User" do
    let(:user) do
      user = create(:user)
      user.spree_roles = []
      d1.enterprise_roles.build(user: user).save
      user
    end

    before :each do
      controller.stub :spree_current_user => user
    end

    describe 'Orders and Distributors' do
      it "only shows orders that I have access to" do
        spree_get :orders_and_distributors
        
        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end
    end

    describe 'Group Buys' do
      it "only shows orders that I have access to" do
        spree_get :group_buys
        
        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end
    end

    describe 'Bulk Coop' do
      it "only shows orders that I have access to" do
        spree_get :bulk_coop
        
        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end
    end

    describe 'Payments' do
      it "only shows orders that I have access to" do
        spree_get :payments
        
        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end
    end

    describe 'Orders & Fulfillment' do
      it "only shows orders that I have access to" do
        spree_get :orders_and_fulfillment

        assigns(:search).result.should include(orderA1, orderB1)
        assigns(:search).result.should_not include(orderA2)
        assigns(:search).result.should_not include(orderB2)
      end

      it "only shows the selected order cycle" do
        spree_get :orders_and_fulfillment, q: {order_cycle_id_eq: ocA.id}

        assigns(:search).result.should include(orderA1)
        assigns(:search).result.should_not include(orderB1)
      end
    end
  end

  # As a Supplier Enterprise user for s1
  context "Supplier" do
    let(:user) do
      user = create(:user)
      user.spree_roles = []
      s1.enterprise_roles.build(user: user).save
      user
    end

    before :each do
      controller.stub :spree_current_user => user
    end

    describe 'Bulk Coop' do
      it "only shows product line items that I am supplying" do
        spree_get :bulk_coop

        assigns(:line_items).map(&:product).should include(p1)
        assigns(:line_items).map(&:product).should_not include(p2)
        assigns(:line_items).map(&:product).should_not include(p3)
      end
    end

    describe 'Orders & Fulfillment' do
      it "only shows product line items that I am supplying" do
        spree_get :orders_and_fulfillment

        assigns(:line_items).map(&:product).should include(p1)
        assigns(:line_items).map(&:product).should_not include(p2)
        assigns(:line_items).map(&:product).should_not include(p3)
      end

      it "only shows the selected order cycle" do
        spree_get :orders_and_fulfillment, q: {order_cycle_id_eq: ocA.id}

        assigns(:search).result.should include(orderA1)
        assigns(:search).result.should_not include(orderB1)
      end
    end
  end
end
