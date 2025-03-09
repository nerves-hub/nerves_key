# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

ExUnit.start()
