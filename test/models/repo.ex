defmodule DlexTest.Repo do
  use Dlex.Repo,
    otp_app: :dlex,
    modules: [DlexTest.Social, DlexTest.User, DlexTest.Team, DlexTest.Ball]
end
