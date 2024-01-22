// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract Inhereth {
    uint256 constant public DURATION = 30 days;
    address public owner;
    address public heir;
    uint256 public periodEndAt;

    event Withdraw(uint256 amount, uint256 newPeriodEndAt);
    event Inheritance(address newOwner, address newHeir);

    error NotOwner();
    error NotHeir();
    error NotEnoughBalance(uint256 balance, uint256 withdrawRequestAmount);
    error PeriodEnded(uint256 periodEndAt, uint256 requestAt);
    error PeriodNotEnded(uint256 periodEndAt, uint256 requestAt);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyHeir() {
        if (msg.sender != heir) {
            revert NotHeir();
        }
        _;
    }

    modifier periodNotEnded() {
        if (block.timestamp > periodEndAt) {
            revert PeriodEnded(periodEndAt, block.timestamp);
        }
        _;
    }

    modifier periodEnded() {
        if (block.timestamp <= periodEndAt) {
            revert PeriodNotEnded(periodEndAt, block.timestamp);
        }
        _;
    }

    constructor(address _heir) payable {
        owner = msg.sender;
        heir = _heir;
        periodEndAt = block.timestamp + DURATION;
    }

    function withdraw(uint256 _amount) external onlyOwner periodNotEnded {
        if (address(this).balance < _amount) {
            revert NotEnoughBalance(address(this).balance, _amount);
        }

        periodEndAt = block.timestamp + DURATION;
        payable(owner).transfer(_amount);

        emit Withdraw(_amount, periodEndAt);
    }

    function resetPeriod() external onlyOwner periodNotEnded {
        periodEndAt = block.timestamp + DURATION;

        emit Withdraw(0, periodEndAt);
    }

    function claimInheritance(address _newHeir) external onlyHeir periodEnded {
        owner = heir;
        heir = _newHeir;
        periodEndAt = block.timestamp + DURATION;

        emit Inheritance(owner, heir);
    }
}
