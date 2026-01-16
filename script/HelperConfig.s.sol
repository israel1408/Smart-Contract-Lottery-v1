// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int96 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callBackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    NetworkConfig private localNetworkConfig;
    mapping(uint256 => NetworkConfig) private networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId)
        public
        returns (NetworkConfig memory)
    {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        }
        revert HelperConfig__InvalidChainId();
    }

    /*//////////////////////////////////////////////////////////////
                              SEPOLIA
    //////////////////////////////////////////////////////////////*/
    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callBackGasLimit: 500_000,
            subscriptionId: 62503109436471671622251321129753169067499856029016821535190259052825438682657, // 👈 REPLACE WITH REAL SUB ID FROM CHAINLINK UI
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account:  0x053F08709AB4a9Ff59847680b92c3a351CF562FB
        });
    }

    /*//////////////////////////////////////////////////////////////
                              ANVIL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilConfig()
        public
        returns (NetworkConfig memory)
    {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock coordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(coordinator),
            gasLane: bytes32(0),
            callBackGasLimit: 500_000,
            subscriptionId: 0, // created in deploy script
            link: address(link),
            account: msg.sender
        });

        return localNetworkConfig;
    }
}
