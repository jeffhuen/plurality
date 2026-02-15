if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule Plurality.Ash.Changes.Pluralize do
    @moduledoc """
    An `Ash.Resource.Change` that sets an attribute to the plural form of
    another attribute.

    ## Options

      * `:attribute` (atom, required) — the attribute to write the plural form to
      * `:from` (atom, required) — the source attribute to read and pluralize

    ## Usage

        change {Plurality.Ash.Changes.Pluralize, attribute: :table_name, from: :resource_name}

    If the source attribute is `nil`, the changeset is returned unchanged.
    """
    use Ash.Resource.Change

    @impl true
    def init(opts) do
      cond do
        not Keyword.has_key?(opts, :attribute) -> {:error, "attribute is required"}
        not is_atom(opts[:attribute]) -> {:error, "attribute must be an atom"}
        not Keyword.has_key?(opts, :from) -> {:error, "from is required"}
        not is_atom(opts[:from]) -> {:error, "from must be an atom"}
        true -> {:ok, opts}
      end
    end

    @impl true
    def change(changeset, opts, _context) do
      value = Ash.Changeset.get_attribute(changeset, opts[:from])

      if is_binary(value) do
        Ash.Changeset.force_change_attribute(
          changeset,
          opts[:attribute],
          Plurality.pluralize(value)
        )
      else
        changeset
      end
    end
  end
end
