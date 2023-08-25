// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

interface IModule {
    function addNodeOperator(string memory _name, address _rewardAddress) external returns (uint256 id);

    function addSigningKeys(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes memory _publicKeys,
        bytes memory _signatures
    ) external;

    function getNodeOperatorsCount() external view returns (uint256);

    function MANAGE_SIGNING_KEYS() external view returns (bytes32);

    function canPerform(address _sender, bytes32 _role, uint256[] memory _params) external view returns (bool);
}

interface IACL {
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] memory _params) external;
}

contract RoleTest is Test {
    address immutable agent = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
    address immutable voting = 0x2e59A20f205bB85a89C53f1936454680651E618e;

    IModule module = IModule(0x55032650b14df07b85bF18A3a3eC8E0Af2e028d5);
    IACL acl = IACL(0x9895F0F17cc1d1891b6f18ee0b483B6f221b37Bb);

    address immutable rewardAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address immutable managerAddress = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    bytes pubkey = hex"81b4ae61a898396903897f94bea0e062c3a6925ee93d30f4d4aee93b533b49551ac337da78ff2ab0cfbb0adb380cad94";
    bytes signature =
        hex"96a88f8e883e9ff6f39751a2cbfca3949f4fa96ae98444d005b6ea9faac0c34b52d595f9428d901ddd813524837d866401ed4ced3d84e7e838a26506ae2ef3bf0bf1b8d38b2bd7bdb6c13c5f46b848d02ddc1108649e9607cf4d2fcecdd807bb";

    uint256 operatorId;

    enum Op {
        NONE,
        EQ,
        NEQ,
        GT,
        LT,
        GTE,
        LTE,
        RET,
        NOT,
        AND,
        OR,
        XOR,
        IF_ELSE
    }

    function setUp() public {
        uint256 mainnetBlock = 17985100;
        vm.createSelectFork(getChain("mainnet").rpcUrl, mainnetBlock);

        _setUpContracts();
        _setUpOperator();
    }

    function _setUpContracts() private {
        vm.deal(agent, 2 ether);
        vm.deal(voting, 2 ether);

        assertGe(address(agent).balance, 1 ether);
        assertGe(address(voting).balance, 1 ether);
    }

    function _setUpOperator() private {
        uint256 operatorsBefore = module.getNodeOperatorsCount();

        vm.prank(agent);
        operatorId = module.addNodeOperator("Test operator", rewardAddress);
        uint256 operatorsAfter = module.getNodeOperatorsCount();

        assertGe(operatorsAfter, operatorsBefore);
    }

    function test_hasNoPermissionForOperator() public {
        assertFalse(_canPerform(managerAddress, operatorId));
    }

    function test_hasPermissionForOperator() public {
        _grantPermission(managerAddress);
        assertTrue(_canPerform(managerAddress, operatorId));
    }

    function test_hasNoPermissionForOtherOperators() public {
        _grantPermission(managerAddress);

        assertFalse(_canPerform(managerAddress, 0));
        assertFalse(_canPerform(managerAddress, operatorId - 1));
    }

    function test_hasNoPermissionForMultiplyOperators() public {
        _grantPermission(managerAddress);

        uint256[] memory operators = new uint256[](2);
        operators[0] = operatorId - 1;
        operators[1] = operatorId;

        assertFalse(_canPerform(managerAddress, operators));
    }

    function test_AddingKeysFromRewardAddress() public {
        _addSigningKey(rewardAddress);
    }

    function test_AddingKeysFromManagerAddressWithoutPermission() public {
        vm.expectRevert(bytes("APP_AUTH_FAILED"));
        _addSigningKey(managerAddress);
    }

    function test_AddingKeysFromManagerAddressWithPermission() public {
        _grantPermission(managerAddress);
        _addSigningKey(managerAddress);
    }

    function _addSigningKey(address from) private {
        vm.prank(from);
        module.addSigningKeys(operatorId, 1, pubkey, signature);
    }

    function _canPerform(address from, uint256 param) private view returns (bool) {
        uint256[] memory params = new uint256[](1);
        params[0] = param;

        return module.canPerform(from, module.MANAGE_SIGNING_KEYS(), params);
    }

    function _canPerform(address from, uint256[] memory params) private view returns (bool) {
        return module.canPerform(from, module.MANAGE_SIGNING_KEYS(), params);
    }

    function _grantPermission(address entity) private {
        bytes32 role = module.MANAGE_SIGNING_KEYS();

        uint256[] memory params = new uint256[](1);
        params[0] = _encodeParam(0, uint8(Op.EQ), uint240(operatorId));

        vm.prank(voting);
        acl.grantPermissionP(entity, address(module), role, params);
    }

    function _encodeParam(uint8 argumentId, uint8 operation, uint240 argumentValue) private pure returns (uint256) {
        return uint256(bytes32(abi.encodePacked(argumentId, operation, argumentValue)));
    }
}
