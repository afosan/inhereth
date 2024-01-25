// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

/**
 * @title Inhereth
 * @dev ether inheritance contract,
        allowing heir to inherit the contract
        in case owner does not withdraw within period
*/
contract Inhereth {
    /// @notice hardcoded duration of period
    uint256 constant public DURATION = 30 days;
    /// @notice owner of the contract
    address public owner;
    /// @notice heir of the contract
    address public heir;
    /// @notice end timestamp of period
    uint256 public periodEndAt;

    /// @notice Event triggered when tokens are bought
    /// @param buyer The address of the account that bought the tokens
    /// @param amount The number of tokens bought

    /// @notice event triggered when owner withdraws
    /// @param amount amount withdrawn
    /// @param amount new value of `periodEndAt`
    /// @dev also triggered by `resetPeriod()`, with `amount` set to 0
    event Withdraw(uint256 amount, uint256 newPeriodEndAt);
    /// @notice event triggered when owner withdraws
    /// @param newOwner new owner of the contract
    /// @param newHeir new heir of the contract
    event Inheritance(address newOwner, address newHeir);

    /// @notice caller is not the owner
    /// @dev `msg.sender` != `owner`
    error NotOwner();
    /// @notice caller is not the heir
    /// @dev `msg.sender` != `heir`
    error NotHeir();
    /// @notice requested withdraw amount exceeds balance of the contract
    /// @param balance balance of the contract before withdraw request
    /// @param withdrawRequestAmount requested withdraw amount
    error NotEnoughBalance(uint256 balance, uint256 withdrawRequestAmount);
    /// @notice period ended
    /// @dev `block.timestamp` > `periodEndAt`
    error PeriodEnded(uint256 periodEndAt, uint256 requestAt);
    /// @notice period not ended
    /// @dev `block.timestamp` <= `periodEndAt`
    error PeriodNotEnded(uint256 periodEndAt, uint256 requestAt);

    /// @notice make sure caller is the owner
    /// @dev success if `msg.sender` == `owner`
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
    /// @notice make sure caller is the heir
    /// @dev success if `msg.sender` == `heir`
    modifier onlyHeir() {
        if (msg.sender != heir) {
            revert NotHeir();
        }
        _;
    }
    /// @notice make sure period is not ended
    /// @dev success if `block.timestamp` <= `periodEndAt`
    modifier periodNotEnded() {
        if (block.timestamp > periodEndAt) {
            revert PeriodEnded(periodEndAt, block.timestamp);
        }
        _;
    }
    /// @notice make sure period is ended
    /// @dev success if `block.timestamp` > `periodEndAt`
    modifier periodEnded() {
        if (block.timestamp <= periodEndAt) {
            revert PeriodNotEnded(periodEndAt, block.timestamp);
        }
        _;
    }

    /// @notice constructs the inheritance contract
    /// @param _heir heir of the contract
    /// @dev `msg.sender` is the `owner` of the contract
    /// @dev initializes `periodEndAt` as well
    constructor(address _heir) payable {
        owner = msg.sender;
        heir = _heir;
        periodEndAt = block.timestamp + DURATION;
    }

    /**
     * @notice owner withdraws requested amount
     * @dev withdraws the amount if possible and resets the `periodEndAt`
     * @param _amount requested withdraw amount
     */
    function withdraw(uint256 _amount) external onlyOwner periodNotEnded {
        if (address(this).balance < _amount) {
            revert NotEnoughBalance(address(this).balance, _amount);
        }

        periodEndAt = block.timestamp + DURATION;
        payable(owner).transfer(_amount);

        emit Withdraw(_amount, periodEndAt);
    }


    /**
     * @notice owner resets the `periodEndsAt`
     * @dev resets the `periodEndAt`
     */
    function resetPeriod() external onlyOwner periodNotEnded {
        periodEndAt = block.timestamp + DURATION;

        emit Withdraw(0, periodEndAt);
    }

    /**
     * @notice heir inherets the contract: becomes the owner and sets its heir
     * @dev resets the `periodEndAt`
     * @param _newHeir new heir for the new owner
     */
    function claimInheritance(address _newHeir) external onlyHeir periodEnded {
        owner = heir;
        heir = _newHeir;
        periodEndAt = block.timestamp + DURATION;

        emit Inheritance(owner, heir);
    }
}
