class Merchant < ApplicationRecord
  validates :name, presence: true

  has_many :items
  has_many :invoices
  has_many :customers, through: :invoices
  has_many :invoice_items, through: :invoices
  has_many :transactions, through: :invoices

  def self.random
    offset = rand(Merchant.count)
    Merchant.offset(offset).first
  end

  def self.top_x_merchants_revenue(amount)
    select("merchants.*, SUM(invoice_items.quantity * invoice_items.unit_price) AS revenue")
      .joins(invoices: [:invoice_items, :transactions])
      .where(transactions: {result: 'success'})
      .order('revenue DESC')
      .group('merchants.id')
      .limit(amount)
  end

  def self.top_x_merchants_items(amount)
    select("merchants.*, SUM(invoice_items.quantity) AS most_items")
      .joins(invoices: [:invoice_items, :transactions])
      .where(transactions: {result: 'success'})
      .order('most_items DESC')
      .group('merchants.id')
      .limit(amount)
  end

  def self.revenue_on_date(date)
    {"total_revenue" => sprintf('%.2f', ((Invoice.where(created_at: date)
      .joins(:invoice_items, :transactions)
      .where(transactions: {result: "success"})
      .sum("unit_price * quantity"))/100.0))}
  end

  def revenue
    {"revenue" => sprintf('%.2f',
    ((invoices.joins(:transactions)
    .where(transactions: {result: "success"})
    .joins(:invoice_items)
    .sum("invoice_items.quantity * invoice_items.unit_price"))/100.0))}
  end

  def revenue_by_date(date)
    {"revenue" => sprintf('%.2f',
    ((invoices.where(invoices: {created_at: date})
    .joins(:transactions)
    .where(transactions: {result: "success"})
    .joins(:invoice_items)
    .sum("invoice_items.quantity * invoice_items.unit_price"))/100.0))}
  end

  def favorite_customer
    customers.select("customers.*, count(invoices.customer_id) as invoice_count")
      .joins(invoices: :transactions)
      .where(transactions: {result: "success"})
      .group("customers.id")
      .order("invoice_count desc").first
  end
end
