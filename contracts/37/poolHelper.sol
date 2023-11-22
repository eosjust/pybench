// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";

import "IBaseRewardPool.sol";
import "IMainStaking.sol";
import "IMasterChefVTX.sol";
import "IMasterPlatypus.sol";

/// @title Poolhelper
/// @author Vector Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Vector protocol
contract PoolHelper {
    using SafeERC20 for IERC20;
    address public immutable depositToken;
    address public immutable stakingToken;
    address public immutable xptp;
    address public immutable masterVtx;

    address public immutable mainStaking;
    address public immutable rewarder;

    uint256 public immutable pid;

    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _mainStaking,
        address _masterVtx,
        address _rewarder,
        address _xptp
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        mainStaking = _mainStaking;
        masterVtx = _masterVtx;
        rewarder = _rewarder;
        xptp = _xptp;
    }

    function totalSupply() public view returns (uint256) {
        return IBaseRewardPool(rewarder).totalSupply();
    }

    /// @notice get the amount of reward per token deposited by a user
    /// @param token the token to get the number of rewards
    /// @return the amount of claimable tokens
    function rewardPerToken(address token) public view returns (uint256) {
        return IBaseRewardPool(rewarder).rewardPerToken(token);
    }

    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(address _address) public view returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /// @notice get the total amount of stables deposited by a user
    /// @return the amount of stables deposited
    function depositTokenBalance() public view returns (uint256) {
        return
            IMainStaking(mainStaking).getDepositTokensForShares(
                balance(msg.sender),
                depositToken
            );
    }

    modifier _harvest() {
        IMainStaking(mainStaking).harvest(depositToken, false);
        _;
    }

    /// @notice harvest pending PTP and get the caller fee
    function harvest() public {
        IMainStaking(mainStaking).harvest(depositToken, true);
        IERC20(xptp).safeTransfer(
            msg.sender,
            IERC20(xptp).balanceOf(address(this))
        );
    }

    /// @notice update the rewards for the caller
    function update() public {
        IBaseRewardPool(rewarder).updateFor(msg.sender);
    }

    /// @notice get the total amount of rewards for a given token for a user
    /// @param token the address of the token to get the number of rewards for
    /// @return vtxAmount the amount of VTX ready for harvest
    /// @return tokenAmount the amount of token inputted
    function earned(address token)
        public
        view
        returns (uint256 vtxAmount, uint256 tokenAmount)
    {
        (vtxAmount, , , tokenAmount) = IMasterChefVTX(masterVtx).pendingTokens(
            stakingToken,
            msg.sender,
            token
        );
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function _stake(uint256 _amount, address sender) internal {
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, sender);
    }

    /// @notice unstake from the masterchief of VTX on behalf of the caller
    function _unstake(uint256 _amount, address sender) internal {
        IMasterChefVTX(masterVtx).withdrawFor(stakingToken, _amount, sender);
    }

    /// @notice deposit stables in mainStaking, autostake in masterchief of VTX
    /// @dev performs a harvest of PTP just before depositing
    /// @param amount the amount of stables to deposit
    function deposit(uint256 amount) external _harvest {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IMainStaking(mainStaking).deposit(depositToken, amount, msg.sender);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);
        emit NewDeposit(msg.sender, amount);
    }

    /// @notice stake the receipt token in the masterchief of VTX on behalf of the caller
    function stake(uint256 _amount) external {
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(stakingToken).approve(masterVtx, _amount);
        IMasterChefVTX(masterVtx).depositFor(stakingToken, _amount, msg.sender);
    }

    /// @notice withdraw stables from mainStaking, auto unstake from masterchief of VTX
    /// @dev performs a harvest of PTP before withdrawing
    /// @param amount the amount of stables to deposit
    function withdraw(uint256 amount, uint256 minAmount) external _harvest {
        _unstake(amount, msg.sender);
        IMainStaking(mainStaking).withdraw(
            depositToken,
            amount,
            minAmount,
            msg.sender
        );
        emit NewWithdraw(msg.sender, amount);
    }

    /// @notice Harvest VTX and PTP rewards
    function getReward() external _harvest {
        IMasterChefVTX(masterVtx).depositFor(stakingToken, 0, msg.sender);
    }

    /// @notice returns the number of pending PTP of the contract for the given pool
    /// returns pendingTokens the number of pending PTP
    function pendingPTP() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterPlatypus(
            IMainStaking(mainStaking).masterPlatypus()
        ).pendingTokens(pid, mainStaking);
    }
}
