#
# This file is part of Edgehog.
#
# Copyright 2023 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.MultitenantResource do
  alias Edgehog.Tenants.Tenant

  @custom_opts [:tenant_id_in_primary_key?]

  defmacro __using__(opts) do
    quote do
      use Ash.Resource,
          unquote(
            opts
            |> Keyword.drop(@custom_opts)
            |> Keyword.put_new(:data_layer, AshPostgres.DataLayer)
          )

      relationships do
        belongs_to :tenant, Edgehog.Tenants.Tenant do
          allow_nil? false
          api Edgehog.Tenants
          destination_attribute :tenant_id
          primary_key? unquote(Keyword.get(opts, :tenant_id_in_primary_key?, false))
        end
      end

      multitenancy do
        strategy :attribute
        attribute :tenant_id
        parse_attribute {Edgehog.MultitenantResource, :parse_tenant_id, []}
      end

      postgres do
        repo Edgehog.Repo

        references do
          reference :tenant, on_delete: :delete
        end
      end
    end
  end

  # Do this so we can do both `tenant: tenant` and `tenant: tenant_id`
  def parse_tenant_id(%Tenant{tenant_id: tenant_id}), do: tenant_id
  def parse_tenant_id(tenant_id), do: tenant_id
end
