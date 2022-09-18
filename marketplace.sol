// "SPDX-License-Identifier: UNLICENSED"   

pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

contract marketplace is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    Counters.Counter private _orderIdCount;
   
    struct Order {
        address seller;
        address buyer;
        uint256 tokenId;
        address paymentToken;
        uint256 price;
    }

    IERC721 public immutable nftContract;
    mapping (uint256 => Order) orders;

    uint256 public feeDecimal;
    uint256 public feeRate;
    address public feeRecipient;
    EnumerableSet.AddressSet private _supportedPaymentTokens;
    event OrderAdded(
        uint256 indexed orderId,
        address indexed seller,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price
    );
    event OrderCanceled (
        uint256 indexed orderId
    );

    event OrderMatched (
        uint256 indexed orderId,
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        address paymentToken,
        uint256 price
    );

    event FeeRateUpdated (
        uint256 feeDecimal,
        uint256 feeRate
    );

    constructor(
        address nftAddress_,
        uint256 feeDecimal_,
        uint256 feeRate_,
        address feeRecipient_
    ) {
        require(
            nftAddress_ != address(0),"NFTMarketplace: nftAddress_ is zero address" 
        );
        require (
            feeRecipient_ != address(0),"NFTMarketplace: feeRecipient"
        );
        nftContract = IERC721(nftAddress_);
        _updateFeeRecipient(feeRecipient_);
        _updateFeeRate(feeDecimal_, feeRate_);
        _orderIdCount.increment();
    }

    function _updateFeeRecipient(address feeRecipient_) internal {
        require (
            feeRecipient_ != address(0),"NFT Marketplace: feeRecipient_ is zero address"
        );
        feeRecipient = feeRecipient_;
    }

    function updateFeeRecipient (address feeRecipient_) external onlyOwner {
        _updateFeeRecipient(feeRecipient_);
    }

    function _updateFeeRate (uint256 feeDecimal_,uint256 feeRate_) internal {
        require (
            feeRate_ < 10**(feeDecimal_+2),"NFT Marketplace: bad fee rate"
        );
        feeDecimal = feeDecimal_;
        feeRate = feeRate_;
    }

    function updateFeeRate (uint feeDecimal_, uint256 feeRate_) external onlyOwner {
        _updateFeeRate(feeDecimal_, feeRate_);
    } 

    function _calculateFee (uint256 orderId_) private view returns (uint256) {
        Order storage _order = orders[orderId_];
        if (feeRate == 0) {
            return 0;
        }
        return (feeRate*_order.price)/10**(feeDecimal+2);
    }

    function isSeller (uint256 orderId_, address seller_) public view returns (bool) {
        return orders[orderId_].seller == seller_;
    }

}
