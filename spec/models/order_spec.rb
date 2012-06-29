require 'spec_helper'

describe Spree::Order do
  it "reveals permission for changing distributor" do
    p = build(:product)

    subject.can_change_distributor?.should be_true
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false
  end

  it "raises an exception if distributor is changed without permission" do
    d = build(:distributor)
    p = build(:product, :distributors => [d])
    subject.distributor = d
    subject.add_variant(p.master, 1)
    subject.can_change_distributor?.should be_false

    expect do
      subject.distributor = nil
    end.to raise_error "You cannot change the distributor of an order with products"
  end

  it "reveals permission for adding products to the cart" do
    d1 = create(:distributor)
    d2 = create(:distributor)

    p_first = create(:product, :distributors => [d1])
    p_subsequent_same_dist = create(:product, :distributors => [d1])
    p_subsequent_other_dist = create(:product, :distributors => [d2])

    # We need to set distributor, since order.add_variant does not, and
    # we also need to save the order so that line items can be added to
    # the association.
    subject.distributor = d1
    subject.save!

    # The first product in the cart can be added
    subject.can_add_product_to_cart?(p_first).should be_true
    subject.add_variant(p_first.master, 1)

    # A subsequent product can be added if the distributor matches
    subject.can_add_product_to_cart?(p_subsequent_same_dist).should be_true
    subject.add_variant(p_subsequent_same_dist.master, 1)

    # And cannot be added if it does not match
    subject.can_add_product_to_cart?(p_subsequent_other_dist).should be_false
  end
end