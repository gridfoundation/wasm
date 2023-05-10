#!/bin/sh

CHAIN_ID=${CHAIN_ID:-furyn-devnet}
MONIKER=${MONIKER:-furyn-devnet-validator}
KEY_NAME=${KEY_NAME:-furyn-devnet-key}
NAMESPACE_ID=${NAMESPACE_ID:-000000000000FFFF}
TOKEN_AMOUNT=${TOKEN_AMOUNT:-10000000000000000000000000uwasm}
STAKING_AMOUNT=${STAKING_AMOUNT:-1000000000uwasm}

rm -rf "$HOME"/.wasmd

wasmd tendermint unsafe-reset-all
wasmd init "$MONIKER" --chain-id "$CHAIN_ID"

sed -i'' -e 's/^minimum-gas-prices *= .*/minimum-gas-prices = "0uwasm"/' "$HOME"/.wasmd/config/app.toml
sed -i'' -e '/\[api\]/,+3 s/enable *= .*/enable = true/' "$HOME"/.wasmd/config/app.toml
sed -i'' -e "s/^chain-id *= .*/chain-id = \"$CHAIN_ID\"/" "$HOME"/.wasmd/config/client.toml
sed -i'' -e '/\[rpc\]/,+3 s/laddr *= .*/laddr = "tcp:\/\/0.0.0.0:26657"/' "$HOME"/.wasmd/config/config.toml
sed -i'' -e 's/"time_iota_ms": "1000"/"time_iota_ms": "10"/' "$HOME"/.wasmd/config/genesis.json
sed -i'' -e 's/bond_denom": ".*"/bond_denom": "uwasm"/' "$HOME"/.wasmd/config/genesis.json
sed -i'' -e 's/mint_denom": ".*"/mint_denom": "uwasm"/' "$HOME"/.wasmd/config/genesis.json

wasmd keys add "$KEY_NAME"
wasmd add-genesis-account "$KEY_NAME" "$TOKEN_AMOUNT"
wasmd gentx "$KEY_NAME" "$STAKING_AMOUNT" --chain-id "$CHAIN_ID"
wasmd collect-gentxs

wasmd start --furyint.aggregator true \
  --furyint.da_layer mock \
  --furyint.settlement_config "{\"root_dir\": \"$HOME/.wasmd\", \"db_path\": \"data\"}" \
  --furyint.settlement_layer mock \
  --furyint.block_batch_size 1000 \
  --furyint.namespace_id "$NAMESPACE_ID" \
  --furyint.block_time 0.2s
