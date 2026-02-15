if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule Plurality.Ash.Changes.Singularize do
    @moduledoc """
    An `Ash.Resource.Change` that sets an attribute to the singular form of
    another attribute.

    ## Options

      * `:attribute` (atom, required) — the attribute to write the singular form to
      * `:from` (atom, required) — the source attribute to read and singularize

    ## Usage

        change {Plurality.Ash.Changes.Singularize, attribute: :resource_name, from: :label}

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
          Plurality.singularize(value)
        )
      else
        changeset
      end
    end
  end
end
