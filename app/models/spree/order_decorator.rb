require 'open_food_web/distribution_change_validator'

ActiveSupport::Notifications.subscribe('spree.order.contents_changed') do |name, start, finish, id, payload|
  payload[:order].reload.update_distribution_charge!
end

Spree::Order.class_eval do
  belongs_to :order_cycle
  belongs_to :distributor, :class_name => 'Enterprise'
  belongs_to :cart

  validate :products_available_from_new_distribution, :if => lambda { distributor_id_changed? || order_cycle_id_changed? }
  attr_accessible :order_cycle_id, :distributor_id

  before_validation :shipping_address_from_distributor


  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('distributor_id IN (?)', user.enterprises.map {|enterprise| enterprise.id })
    end
  }


  # -- Methods
  def products_available_from_new_distribution
    # Check that the line_items in the current order are available from a newly selected distribution
    if OpenFoodWeb::FeatureToggle.enabled? :order_cycles
      errors.add(:base, "Distributor or order cycle cannot supply the products in your cart") unless DistributionChangeValidator.new(self).can_change_to_distribution?(distributor, order_cycle)
    else
      errors.add(:distributor_id, "cannot supply the products in your cart") unless DistributionChangeValidator.new(self).can_change_to_distributor?(distributor)
    end
  end

  def set_order_cycle!(order_cycle)
    self.order_cycle = order_cycle
    self.distributor = nil unless self.order_cycle.andand.has_distributor? distributor
    save!
  end

  def set_distributor!(distributor)
    self.distributor = distributor
    self.order_cycle = nil unless self.order_cycle.andand.has_distributor? distributor
    save!
  end

  def set_distribution!(distributor, order_cycle)
    self.distributor = distributor
    self.order_cycle = order_cycle
    save!
  end

  def update_distribution_charge!
    line_items.each do |line_item|
      pd = product_distribution_for line_item
      pd.ensure_correct_adjustment_for line_item if pd
    end
  end

  def set_variant_attributes(variant, attributes)
    line_item = find_line_item_by_variant(variant)

    if attributes.key?(:max_quantity) && attributes[:max_quantity].to_i < line_item.quantity
      attributes[:max_quantity] = line_item.quantity
    end

    line_item.assign_attributes(attributes)
    line_item.save!
  end

  def line_item_variants
    line_items.map { |li| li.variant }
  end

  # Show payment methods with no distributor or for this distributor
  def available_payment_methods
    @available_payment_methods ||= Spree::PaymentMethod.available(:front_end).select do |pm| 
      (self.distributor && (pm.distributor == self.distributor)) || pm.distributor == nil
    end
  end

  private

  def shipping_address_from_distributor
    if distributor
      self.ship_address = distributor.address.clone

      if bill_address
        self.ship_address.firstname = bill_address.firstname
        self.ship_address.lastname = bill_address.lastname
        self.ship_address.phone = bill_address.phone
      end
    end
  end

  def product_distribution_for(line_item)
    line_item.variant.product.product_distribution_for self.distributor
  end

end
