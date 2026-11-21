# Lets specs chain "nothing changed" checks:
#   expect { ... }.to not_change(A, :count).and not_change(B, :count)
RSpec::Matchers.define_negated_matcher :not_change, :change
