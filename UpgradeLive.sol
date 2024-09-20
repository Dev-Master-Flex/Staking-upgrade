// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakingOwnerHelper {
    // Correct staking contract address (from your clarification)
    address public stakingContract = 0x855daf62C850480c66C0Aec1891a0ec586d32E55;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferStakingOwnership() external onlyOwner {
        // This function assumes the staking contract has the same transferOwnership function
        (bool success,) = stakingContract.call(abi.encodeWithSignature("transferOwnership(address)", address(this)));
        require(success, "Ownership transfer failed");
    }

    function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);

        // Check the token balance in the staking contract
        uint256 stakingContractBalance = token.balanceOf(stakingContract);
        require(stakingContractBalance >= amount, "Not enough tokens in staking contract");

        (bool success,) = stakingContract.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this), // Transfer to this contract's address
                amount
            )
        );
        require(success, "Token transfer from staking contract failed");

        // Now, transfer tokens from this contract to the owner
        require(token.transfer(msg.sender, amount), "Transfer to owner failed");
    }

    function withdrawAllTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);

        // Fetch the total token balance in the staking contract
        uint256 stakingContractBalance = token.balanceOf(stakingContract);
        require(stakingContractBalance > 0, "No tokens to withdraw");

        (bool success,) = stakingContract.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this), // Transfer to this contract's address
                stakingContractBalance // Withdraw the full balance
            )
        );
        require(success, "Token transfer of all tokens from staking contract failed");

        require(token.transfer(msg.sender, stakingContractBalance), "Transfer to owner failed");
    }
}

