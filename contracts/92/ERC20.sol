// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Ownable, IERC20, IERC20Metadata {
	using SafeMath for uint256;
	
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
	uint8 private _decimals = 18;
    string private _name;
    string private _symbol;
	
	mapping(address => bool) private isExcludedTxFee;
    
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _marketerAddress1 = 0xc73F7Ab1d3d1122763244080c205A5b79B00B2fa;
    address private _marketerAddress2 = 0x1Fe9a7D2F32279fD4Fe78516622b1D4561A1Eb0B;
    address private _lpAdminerAddress = 0xb1ECca5295bD589559aEC0dB555FD885c29ed427;
    address private _lpFeeReceiveAddress = 0xf8C4068Bb809fFEE1168C7a818E3E0a0ca337EcA;

	address public uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address public uniswapV2Pair;
	mapping(address => address) public inviter;
	
	mapping(address => bool) private isLpShareholder;
	address[] public _lpShareholderArray;
	mapping (address => uint256) private _lpShareholderIndexeMapping;
    
    bool private takeFee = true;
    uint256 public burnTotalAmount;

	uint8 private _burnFee = 2;
    uint8 private _marketFee = 1;
	uint8 private _lpFee = 1;
    uint8 private _lpShareHolderFee = 3;
	uint8 private _inviterFee = 3;
    uint8 [6] private _inviterFeeA = [8, 6, 13, 1, 1, 1];

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        isExcludedTxFee[msg.sender] = true;
        isExcludedTxFee[address(this)] = true;
        isExcludedTxFee[_lpFeeReceiveAddress] = true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);
		
		//indicates if fee should be deducted from transfer
		bool _takeFee = takeFee;
		
		//if any account belongs to isExcludedTxFee account then remove the fee
		if (isExcludedTxFee[from] || isExcludedTxFee[to] || from == uniswapV2Router) {
		    _takeFee = false;
		}

		bool shouldSetInviter = balanceOf(to) == 0 && inviter[to] == address(0) && from != uniswapV2Pair;
		if(_takeFee){
            _transferFee(from, to, amount);
		}else{
		    _transferStandard(from, to, amount);
		}
        
		if (shouldSetInviter) {
			inviter[to] = from;
		}

        if(uniswapV2Pair != address(0) && from != uniswapV2Pair){
            addLpShareholder(from);
        }

        if(uniswapV2Pair != address(0) && to != uniswapV2Pair){
            addLpShareholder(to);
        }

        _afterTokenTransfer(from, to, amount);
    }

    uint256 public batchCount = 100;
    uint256 public currentIndex;
    uint256 public tempLpFeeBanance;
    uint public lpBonusTime;

    function lpBonus() public {
        uint256 shareholderCount = _lpShareholderArray.length;
        if(shareholderCount == 0)return;
        if(tempLpFeeBanance == 0){
            tempLpFeeBanance = _balances[_lpFeeReceiveAddress];
        }
        uint256 counter = 0;
        while(counter < batchCount && currentIndex < shareholderCount){
            uint256 lpBalance = IERC20(uniswapV2Pair).balanceOf(_lpShareholderArray[currentIndex]);
            uint256 amount = tempLpFeeBanance.mul(lpBalance).div(IERC20(uniswapV2Pair).totalSupply());
            if(_balances[_lpFeeReceiveAddress] >= amount){
                _balances[_lpFeeReceiveAddress] = _balances[_lpFeeReceiveAddress].sub(amount);
                _balances[_lpShareholderArray[currentIndex]] = _balances[_lpShareholderArray[currentIndex]].add(amount);
                emit Transfer(_lpFeeReceiveAddress, _lpShareholderArray[currentIndex], amount);
            }
            counter++;
            currentIndex++;
        }

        if(currentIndex >= shareholderCount){
            currentIndex = 0;
            tempLpFeeBanance = 0;
            lpBonusTime = block.timestamp;
        }
    }
	
	function _transferFee(
	    address from,
	    address to,
	    uint256 amount
	) internal virtual {
		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		
		//buy
		if(from == uniswapV2Pair){
		    _takeBurnFee(from, amount.div(100).mul(_burnFee));   
            _takeMarketerFee(amount.div(100).mul(_marketFee));
		    _takeLPFee(amount.div(100).mul(_lpFee));
            _takeLPReceiveFee(from, amount.mul(_lpShareHolderFee).div(100));
		    _takeInviterFee(from, to, amount);

            uint256 recipientRate = 100 - _burnFee - _marketFee*2 - _lpFee - _lpShareHolderFee - _inviterFee;
		    _balances[to] = _balances[to].add(amount.div(100).mul(recipientRate));
		    emit Transfer(from, to, amount.div(100).mul(recipientRate));
		
		//sell
		}else if(to == uniswapV2Pair){
		    _balances[to] = _balances[to].add(amount);
		    emit Transfer(from, to, amount);
		//transfer
		}else{
		    _takeBurnFee(from, amount.div(100).mul(_burnFee));
            _takeMarketerFee(amount.div(100).mul(_marketFee));
            _takeLPFee(amount.div(100).mul(_lpFee));
            _takeLPReceiveFee(from, amount.mul(_lpShareHolderFee).div(100));
		    _takeInviterFee(from, to, amount);
		
		    uint256 recipientRate = 100 - _burnFee - _marketFee*2 - _lpFee - _lpShareHolderFee - _inviterFee;
		    _balances[to] = _balances[to].add(amount.div(100).mul(recipientRate));
		    emit Transfer(from, to, amount.div(100).mul(recipientRate));
		}
        
		unchecked {
		    _balances[from] = fromBalance - amount;
		}
	}
	
	function _transferStandard(
	    address from,
	    address to,
	    uint256 amount
	) internal virtual {
	    uint256 fromBalance = _balances[from];
	    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
	    unchecked {
	        _balances[from] = fromBalance - amount;
	    }
	    _balances[to] += amount;
	
	    emit Transfer(from, to, amount);
	}

    function setLPAddress(address lpAddress) public virtual onlyOwner returns(bool){
        uniswapV2Pair = lpAddress;
        return true;
    }

    function setBatchCount(uint256 batchCount_) public virtual onlyOwner returns(bool){
        batchCount = batchCount_;
        return true;
    }

    function addExcludedTxFeeAccount(address account) public virtual onlyOwner returns(bool){
        if(isExcludedTxFee[account]){
            isExcludedTxFee[account] = false;
        }else{
            isExcludedTxFee[account] = true;
        }
        return true;
    }
    function setTakeFee(bool _takeFee) public virtual onlyOwner returns(bool){
        takeFee = _takeFee;
        return true;
    }
	
	function _takeInviterFee(address sender,address recipient,uint256 tAmount) private {
	    if (_inviterFee == 0) return;
	    address rewardAddress;
	    if (sender == uniswapV2Pair) {
	        rewardAddress = recipient;
	    } else {
	      rewardAddress = sender;
	    }
	    uint outRate = 0;
	    for (uint8 i = 0; i < 6; i++) {
	        rewardAddress = inviter[rewardAddress];
	        if (rewardAddress == address(0)) {
	            break;
	        }
            outRate += _inviterFeeA[i];
	        uint256 rewardAmount = tAmount.mul(_inviterFeeA[i]).div(1000);
	        _balances[rewardAddress] = _balances[rewardAddress].add(rewardAmount);
	        emit Transfer(sender, rewardAddress, rewardAmount);
	    }

        if(outRate < 30){
            _balances[address(this)] = _balances[address(this)].add(tAmount.mul(30-outRate).div(1000));
            emit Transfer(sender, address(this), tAmount.mul(30-outRate).div(1000));
        }
	}
	
	function _takeBurnFee(address sender,uint256 tAmount) private {
        if(_burnAddress == 0x000000000000000000000000000000000000dEaD){
            uint _burnAmount = burnTotalAmount.add(tAmount);
            if(_burnAmount > 16453 * 10**_decimals){
                uint _bAmount = 16453 * 10**_decimals - burnTotalAmount;
                _totalSupply = _totalSupply.sub(_bAmount);
                _balances[_burnAddress] = _balances[_burnAddress].add(_bAmount);
                emit Transfer(sender, _burnAddress, _bAmount);
                burnTotalAmount = 16453 * 10**_decimals;
                tAmount = _burnAmount.sub(burnTotalAmount);
                _burnAddress = 0x6C8f0Cc09f7AAdf1f4eC599E2a16Ee941B7F9e05;
                _balances[_burnAddress] = _balances[_burnAddress].add(tAmount);
                
            }
            else{
                _balances[_burnAddress] = _burnAmount;
                _totalSupply = _totalSupply.sub(tAmount);
            }
        }
        else{
            _balances[_burnAddress] = _balances[_burnAddress].add(tAmount);
        }

        emit Transfer(sender, _burnAddress, tAmount);
	}

    function _takeLPReceiveFee(address sender, uint256 tAmount) private {
	    _balances[_lpFeeReceiveAddress] = _balances[_lpFeeReceiveAddress].add(tAmount);
        emit Transfer(sender, _lpFeeReceiveAddress, tAmount);
	}

	function _takeLPFee(uint256 tAmount) private {
	    _balances[_lpAdminerAddress] = _balances[_lpAdminerAddress].add(tAmount);
	}
    function _takeMarketerFee(uint256 tAmount) private {
        _balances[_marketerAddress1] = _balances[_marketerAddress1].add(tAmount);
        _balances[_marketerAddress2] = _balances[_marketerAddress2].add(tAmount);
    }

    function addLpShareholder(address shareholder) internal {
        if(isLpShareholder[shareholder]){      
            if(IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) removeLpShareholder(shareholder);
            return;
        }

        if(IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return; 

        _lpShareholderIndexeMapping[shareholder] = _lpShareholderArray.length;
        _lpShareholderArray.push(shareholder);
        isLpShareholder[shareholder] = true;
    }

    function removeLpShareholder(address shareholder) internal {
        _lpShareholderArray[_lpShareholderIndexeMapping[shareholder]] = _lpShareholderArray[_lpShareholderArray.length-1];
        _lpShareholderIndexeMapping[_lpShareholderArray[_lpShareholderArray.length-1]] = _lpShareholderIndexeMapping[shareholder];
        _lpShareholderArray.pop();
        isLpShareholder[shareholder] = false;
    }
	
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}