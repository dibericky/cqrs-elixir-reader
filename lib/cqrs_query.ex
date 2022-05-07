alias CqrsQuery.Repo

defmodule InventoryEvents do
  defstruct event_id: nil, event_type_id: nil, description: nil,	sku: nil,	qty: nil
end

defmodule Product do
  defstruct sku: nil,	qty: nil, last_event_id: nil
end

defmodule CqrsQuery do
  def map_row_to_inventory (row) do
    event_id = Enum.at(row, 0)
    event_type_id = Enum.at(row, 1)
    description = Enum.at(row, 2)
    sku = Enum.at(row, 3)
    qty = Enum.at(row, 4)
    
    %InventoryEvents{event_id: event_id, event_type_id: event_type_id, description: description, sku: sku, qty: qty}
  end

  def get_events(sku) do
    result = Repo.query!("""
      select event_id, I.event_type_id as event_type_id, description, sku, qty from inventory_events as I, event_types as E where sku = $1 and I.event_type_id = E.event_type_id
      order by event_id ASC
      """, [sku])
    result.rows 
      |> Enum.map(fn row -> map_row_to_inventory(row) end)
  end

  def apply_event(event, product) do
    qty = case event.event_type_id do
      "product_added" -> event.qty
      "product_sold" -> -event.qty
    end
    product_qty = case product do
      p when product != nil -> p.qty
      _ -> 0
    end
    %Product { sku: event.sku, qty: product_qty + qty, last_event_id: event.event_id }
  end

  def resolve_product(sku) do
    get_events(sku)
    |> Enum.reduce(nil, &(apply_event(&1, &2)))
  end

  def save_product(product) do
    %Product { :sku => sku, :qty => qty, :last_event_id => last_event_id } = product
    query = """
    INSERT INTO product (sku, qty, last_event_id) VALUES ($1, $2, $3)
    ON CONFLICT(sku) DO UPDATE SET qty = $2, last_event_id = $3
    """
    result = Repo.query!(query, [sku, qty, last_event_id])
    result
  end

  def reload_product(sku) do
    p = CqrsQuery.resolve_product(sku)
    CqrsQuery.save_product(p)
  end

  def build_product_detail(product) do
    %{ :sku => Enum.at(product, 0), :qty => Enum.at(product, 1), :last_event_id => Enum.at(product, 2), :last_event_description => Enum.at(product, 3)}
  end

  def get_product(sku) do
    query = """
    select product.sku, product.qty, last_event_id, description
      from product
      left join inventory_events
    on product.last_event_id = inventory_events.event_id
    left join event_types
      on inventory_events.event_type_id = event_types.event_type_id 
    where product.sku = $1
"""
    result = Repo.query!(query, [sku]).rows
    case length(result) do
      0 -> nil
      _ -> build_product_detail(Enum.at(result, 0))
    end
  end

  def main do
   reload_product("abc")
  end
end
