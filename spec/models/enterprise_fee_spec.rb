require 'spec_helper'

describe EnterpriseFee do
  describe "associations" do
    it { should belong_to(:enterprise) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "clearing all enterprise fee adjustments for a line item" do
    it "clears adjustments originating from many different enterprise fees" do
      p = create(:simple_product)
      d1, d2 = create(:distributor_enterprise), create(:distributor_enterprise)
      pd1 = create(:product_distribution, product: p, distributor: d1)
      pd2 = create(:product_distribution, product: p, distributor: d2)
      line_item = create(:line_item, product: p)
      pd1.enterprise_fee.create_adjustment('foo1', line_item.order, line_item, true)
      pd2.enterprise_fee.create_adjustment('foo2', line_item.order, line_item, true)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(-2)
    end

    it "does not clear adjustments originating from another source" do
      p = create(:simple_product)
      pd = create(:product_distribution)
      line_item = create(:line_item, product: pd.product)
      tax_rate = create(:tax_rate, calculator: build(:calculator, preferred_amount: 10))
      tax_rate.create_adjustment('foo', line_item.order, line_item)

      expect do
        EnterpriseFee.clear_all_adjustments_for line_item
      end.to change(line_item.order.adjustments, :count).by(0)
    end
  end

  describe "clearing all enterprise fee adjustments on an order" do
    it "clears adjustments from many fees and one all line items" do
      order = create(:order)

      p1 = create(:simple_product)
      p2 = create(:simple_product)
      d1, d2 = create(:distributor_enterprise), create(:distributor_enterprise)
      pd1 = create(:product_distribution, product: p1, distributor: d1)
      pd2 = create(:product_distribution, product: p1, distributor: d2)
      pd3 = create(:product_distribution, product: p2, distributor: d1)
      pd4 = create(:product_distribution, product: p2, distributor: d2)
      line_item1 = create(:line_item, order: order, product: p1)
      line_item2 = create(:line_item, order: order, product: p2)
      pd1.enterprise_fee.create_adjustment('foo1', line_item1.order, line_item1, true)
      pd2.enterprise_fee.create_adjustment('foo2', line_item1.order, line_item1, true)
      pd3.enterprise_fee.create_adjustment('foo3', line_item2.order, line_item2, true)
      pd4.enterprise_fee.create_adjustment('foo4', line_item2.order, line_item2, true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(-4)
    end

    it "does not clear adjustments from another originator" do
      order = create(:order)
      tax_rate = create(:tax_rate, calculator: stub_model(Spree::Calculator))
      order.adjustments.create({:amount => 12.34,
                                :source => order,
                                :originator => tax_rate,
                                :locked => true,
                                :label => 'hello' }, :without_protection => true)

      expect do
        EnterpriseFee.clear_all_adjustments_on_order order
      end.to change(order.adjustments, :count).by(0)
    end
  end
end
