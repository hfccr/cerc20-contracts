// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import { ConfidentialToken } from "../ConfidentialERC20/ConfidentialToken.sol";
import "./Interfaces/ITransferRules.sol";

contract CompliantConfidentialERC20 is ConfidentialToken {
    ITransferRules public transferRulesContract;
    constructor(address _transferRulesContract) ConfidentialToken("Compliant cUSDC", "ccUSDC") {
        transferRulesContract = ITransferRules(_transferRulesContract);
    }
    mapping(address => bool) public auditor;

    // Overridden transfer function handling encrypted inputs
    function transfer(
        address to,
        einput encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (bool) {
        euint64 amount = TFHE.asEuint64(encryptedAmount, inputProof);
        return transfer(to, amount);
    }

    // Internal transfer function applying the transfer rules
    function transfer(address to, euint64 amount) public override returns (bool) {
        require(TFHE.isSenderAllowed(amount), "Sender not allowed");

        ebool hasEnough = TFHE.le(amount, _balances[msg.sender]);
        euint64 transferAmount = TFHE.select(hasEnough, amount, TFHE.asEuint64(0));

        // Apply transfer rules
        TFHE.allow(transferAmount, address(transferRulesContract));
        ebool rulesPassed = transferRulesContract.transferAllowed(msg.sender, to, transferAmount);
        transferAmount = TFHE.select(rulesPassed, transferAmount, TFHE.asEuint64(0));

        TFHE.allow(transferAmount, address(this));
        _transfer(msg.sender, to, transferAmount);

        return true;
    }

    function becomeAuditor() public {
        auditor[msg.sender] = true;
    }

    function revokeAuditor() public {
        auditor[msg.sender] = false;
    }

    // Internal transfer function with encrypted balances
    function _transfer(address from, address to, euint64 _amount) internal {
        euint64 newBalanceFrom = TFHE.sub(_balances[from], _amount);
        _balances[from] = newBalanceFrom;
        TFHE.allow(newBalanceFrom, from);

        euint64 newBalanceTo = TFHE.add(_balances[to], _amount);
        _balances[to] = newBalanceTo;
        TFHE.allow(newBalanceTo, address(this));
        TFHE.allow(newBalanceTo, to);
    }

    // Allows admin to view any user's encrypted balance
    function adminViewUserBalance(address user) public onlyOwner {
        TFHE.allow(_balances[user], owner());
    }

    function auditorViewUserBalance(address user) public {
        require(auditor[msg.sender], "Not an auditor");
        TFHE.allow(_balances[user], msg.sender);
    }

    function isAuditor() public view returns (bool) {
        return auditor[msg.sender];
    }

    function isAddressAuditor(address _address) public view returns (bool) {
        return auditor[_address];
    }
}
