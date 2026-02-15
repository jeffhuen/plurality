if Code.ensure_loaded?(Ash.Resource.Calculation) do
  defmodule Plurality.Ash.Calculations.Singularize do
    @moduledoc """
    An `Ash.Resource.Calculation` that derives the singular form of an attribute.

    ## Options

      * `:attribute` (atom, required) — the source attribute to singularize

    ## Usage

        calculations do
          calculate :name_singular, :string, {Plurality.Ash.Calculations.Singularize, attribute: :name}
        end

    Returns `nil` if the source attribute is `nil`.
    """
    use Ash.Resource.Calculation

    @impl true
    def init(opts) do
      cond do
        not Keyword.has_key?(opts, :attribute) -> {:error, "attribute is required"}
        not is_atom(opts[:attribute]) -> {:error, "attribute must be an atom"}
        true -> {:ok, opts}
      end
    end

    @impl true
    def load(_query, opts, _context) do
      [opts[:attribute]]
    end

    @impl true
    def calculate(records, opts, _context) do
      Enum.map(records, fn record ->
        case Map.get(record, opts[:attribute]) do
          nil -> nil
          value when is_binary(value) -> Plurality.singularize(value)
          _ -> nil
        end
      end)
    end
  end
end
