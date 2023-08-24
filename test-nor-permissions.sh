aragon_agent_contract=0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c
aragon_voting_contract=0x2e59A20f205bB85a89C53f1936454680651E618e
nor_contract=0x55032650b14df07b85bF18A3a3eC8E0Af2e028d5
acl_contract=0x9895F0F17cc1d1891b6f18ee0b483B6f221b37Bb

account_1=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
account_2=0xd8da6bf26964af9d7eed9e03e53415d37aa96045

pubkey=0x81b4ae61a898396903897f94bea0e062c3a6925ee93d30f4d4aee93b533b49551ac337da78ff2ab0cfbb0adb380cad94
signature=0x96a88f8e883e9ff6f39751a2cbfca3949f4fa96ae98444d005b6ea9faac0c34b52d595f9428d901ddd813524837d866401ed4ced3d84e7e838a26506ae2ef3bf0bf1b8d38b2bd7bdb6c13c5f46b848d02ddc1108649e9607cf4d2fcecdd807bb

MANAGE_SIGNING_KEYS=0x75abc64490e17b40ea1e66691c3eb493647b24430b358bd87ec3e5127f1621ee

# run fork first:
# anvil --fork-url https://eth-mainnet.alchemyapi.io/v2/Lc7oIGYeL_QvInzI0Wiu_pOZZDEKBrdf

# snapshot
snapshot_id=$(cast rpc evm_snapshot)

# impersonate accounts
cast rpc anvil_impersonateAccount $account_1 > /dev/null
cast rpc anvil_impersonateAccount $account_2 > /dev/null
cast rpc anvil_impersonateAccount $aragon_agent_contract > /dev/null
cast rpc anvil_impersonateAccount $aragon_voting_contract > /dev/null

# fund aragon contract
echo "funding aragon contracts..."
cast rpc anvil_setBalance $aragon_agent_contract 0x1000000000000000 > /dev/null
cast rpc anvil_setBalance $aragon_voting_contract 0x1000000000000000 > /dev/null
echo "done\n"

# add new operator
echo "adding new operator..."
cast send $nor_contract --unlocked --from $aragon_agent_contract --gas-limit 1000000 "addNodeOperator(string,address)(uint256)" "Test operator" $account_1 > /dev/null
echo "done\n"

# get operator id
operator_id=$(($(cast call $nor_contract "getNodeOperatorsCount()(uint256)") - 1))
echo "operator with id $operator_id added to the module\n"

# add signing key
echo "try adding signing key from reward address..."
cast call $nor_contract --from $account_1 "addSigningKeys(uint256,uint256,bytes,bytes)" $operator_id 1 $pubkey $signature > /dev/null
echo "done\n"

echo "set permissions for manager address..."
# cast call $acl_contract --trace --verbose --from $aragon_voting_contract "grantPermissionP(address,address,bytes32,uint256[])" $account_2 $nor_contract $MANAGE_SIGNING_KEYS [$operator_id]
cast send $acl_contract --unlocked --from $aragon_voting_contract --gas-limit 1000000 "grantPermissionP(address,address,bytes32,uint256[])" $account_2 $nor_contract $MANAGE_SIGNING_KEYS "[$operator_id]"
# cast send $acl_contract --unlocked --from $aragon_voting_contract --gas-limit 1000000 "grantPermission(address,address,bytes32)" $account_2 $nor_contract $MANAGE_SIGNING_KEYS
echo "done\n"

# cast call $nor_contract "canPerform(address,bytes32,uint256[])(bool)" $account_2 $MANAGE_SIGNING_KEYS "[$operator_id]"
# cast call $acl_contract "hasPermission(address,address,bytes32,uint256[])(bool)" $account_2 $nor_contract $MANAGE_SIGNING_KEYS "[$operator_id]"
cast call --trace $nor_contract "canPerform(address,bytes32,uint256[])(bool)" $account_2 $MANAGE_SIGNING_KEYS "[$operator_id]"

echo "try adding signing key from manager address..."
# cast call $nor_contract --from $account_2 "addSigningKeys(uint256,uint256,bytes,bytes)" $operator_id 1 $pubkey $signature > /dev/null
echo "done\n"

# revert
cast rpc evm_revert $snapshot_id && echo "reverted to snapshot $snapshot_id\n"