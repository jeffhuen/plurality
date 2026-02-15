%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: %{
        extra: [
          # Dispatch functions use large case statements by design (last-byte
          # dispatch with many suffix branches). Raising the threshold avoids
          # false positives on these intentionally complex pattern-match functions.
          {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 14}
        ]
      }
    }
  ]
}
