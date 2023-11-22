// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterPlatypus {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function userInfo(uint256 _pid, address _address)
        external
        view
        returns (
            uint256 amount,
            uint256 debt,
            uint256 factor
        );
}
