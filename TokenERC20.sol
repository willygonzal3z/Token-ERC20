// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TokenERC20 is IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    
    // Cambia la dirección del Dueño del Token
    // Change Owner Address
    address private _developmentWalletAddress = 0x0000000000000000000000000000000;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tFeeTotal;
    uint256 private _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _developmentFee = 0;
    uint256 private _previousDevelopmentFee = _developmentFee;
    uint256 private _liquidityFee = 0;
    uint256 private _previousLiquidityFee = _liquidityFee;

    constructor() {
        _name = "TOKEN NAME";
        _symbol = "TKS";
        _totalSupply = 50000000000 * 10 ** decimals();
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
 
         require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        // Aplica las tarifas correspondientes
        // Applies the corresponding rates
        uint256 taxAmount = amount.mul(_taxFee).div(100);
        uint256 developmentAmount = amount.mul(_developmentFee).div(100);
        uint256 liquidityAmount = amount.mul(_liquidityFee).div(100);

        // Resta las tarifas del monto transferido
        //Subtract fees from the amount transferred
        uint256 transferAmount = amount.sub(taxAmount).sub(developmentAmount).sub(liquidityAmount);

        // Actualiza los saldos
        // Update balances
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(transferAmount);

        // Aplica las tarifas al saldo de desarrollo y quema los tokens de tarifas
        // Apply fees to development balance and burn fee tokens
        _balances[_developmentWalletAddress] = _balances[_developmentWalletAddress].add(developmentAmount);
        _burn(sender, taxAmount);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        _tFeeTotal = _tFeeTotal.add(amount);

        emit Transfer(account, address(0), amount);
    }
}