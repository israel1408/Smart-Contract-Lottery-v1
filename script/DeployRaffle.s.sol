// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {
    CreateSubscription,
    FundSubscription,
    AddConsumer
} from "script/Interactions.s.sol";

contract DeployRaffle is Script, CodeConstants {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        uint256 subId = config.subscriptionId;

        // 👇 ONLY do this on LOCAL
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            CreateSubscription createSub = new CreateSubscription();
            (subId, config.vrfCoordinator) = createSub.createSubscription(
                config.vrfCoordinator,
                config.account
            );

            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(
                config.vrfCoordinator,
                subId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            subId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();

        // 👇 ONLY add consumer on LOCAL (Sepolia requires sub owner)
        if (block.chainid == 31337) {
            AddConsumer addConsumer = new AddConsumer();
            addConsumer.addConsumer(
                address(raffle),
                config.vrfCoordinator,
                subId,
                config.account
            );
        }

        return (raffle, helperConfig);
    }
}
