pragma solidity ^0.5.9;

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TradeableERC721Token is ERC721Full, Ownable, Pausable {

    struct STYLE {
        uint id;
        uint maxMint;
        uint totalMinted;
        string metaUrl;
    }
    
    //Total supply of minted styles
    uint256 _totalSupply = 0;

    //STYLE objects with ID that can be minted
    mapping (uint256 => STYLE) _styles;
    //Alias each token ID to a style type
    mapping (uint256 => uint256) _tokenIdToStyle;
    
    //Event for STYLE updates
    event NewMapStyleAdded(uint id, uint maxMint, uint totalMinted, string metaUrl);
    event MapStyleUriUpdated(uint id, string metaUrl);

    address proxyRegistryAddress;
    
    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) ERC721Full(_name, _symbol) public {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
 
  /**
    * @dev Mints bulk amount to address (owner)
    * @param _to address of the future owner of the token
    */
  function bulkMintTo(uint256 mintAmount, address _to, uint256 _styleId) public onlyOwner {
    for (uint256 i = 0; i < mintAmount; i++) {
        mintTo(_to, _styleId);
     }
  }

   /**
    * @dev Mints bulk amount of same token with given meta to array of addresses
    */
  function bulkMintArray(address[] memory receivers, uint256 _styleId) public onlyOwner {
     for (uint256 i = 0; i < receivers.length; i++) {
        mintTo(receivers[i], _styleId);
     }
  }
  
        /**
    * @dev Mints a token to an address with a tokenURI.
    * @param _to address of the future owner of the token
    */
  function mintTo(address _to, uint256 _styleId) public onlyOwner {
    uint256 _newTokenId = _getNextTokenId();
    STYLE memory _style = styleFromStyleId(_styleId);
    require(_style.maxMint < _style.totalMinted, "The max tokens for this style have already been minted!");
    _tokenIdToStyle[_newTokenId] = _styleId;
    _mint(_to, _newTokenId);
    _incrementTokenId(_style);
  }

  function _incrementTokenId(STYLE memory _style) private  {
    _style.totalMinted++;
    _totalSupply++;
  }
  
  //To update if setting custom uri is opened
    function updateStyleUri(uint256 _styleId, string memory _uri) public onlyOwner{
        STYLE memory _style = styleFromStyleId(_styleId);
        _style.metaUrl = _uri;
        emit MapStyleUriUpdated(_styleId, _uri);
    }
  
  /**
    * @dev calculates the next token ID based on value of _currentTokenId 
    * @return uint256 for the next token ID
    */
  function _getNextTokenId() private view returns (uint256) {
    return _totalSupply.add(1);
  }

    //Returns the metadata uri for the token
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return _styles[_tokenIdToStyle[_tokenId]].metaUrl;
    } 

    //Returns STYLE object based on the styleId
    function styleFromStyleId(uint256 _styleId) internal view returns (STYLE memory) {
        return _styles[_styleId];
    }

    //Returns STYLE object based on the tokenId
    function styleObjectForTokenId(uint256 _tokenId) internal view returns (STYLE memory) {
        return _styles[_tokenIdToStyle[_tokenId]];
    }
    
     //Returns STYLE object based on the styleId
    function styleMetaFromStyleId(uint256 _styleId) public view returns (uint id, uint maxMint, uint totalMinted, string memory metaUrl) {
        STYLE memory _style = styleFromStyleId(_styleId);
        return (_style.id, _style.maxMint, _style.totalMinted, _style.metaUrl);
    }

    //Returns STYLE object based on the tokenId
    function styleMetaObjectForTokenId(uint256 _tokenId) public view returns (uint id, uint maxMint, uint totalMinted, string memory metaUrl) {
        STYLE memory _style = _styles[_tokenIdToStyle[_tokenId]];
        return (_style.id, _style.maxMint, _style.totalMinted, _style.metaUrl);
    }

    //Add a new mintable STYLE 
    function addNewStyle(uint256 _id, uint _maxMint, uint _totalMint, string memory _metaUrl) public onlyOwner {
        STYLE memory style = STYLE(_id, _maxMint, _totalMint, _metaUrl);
        _styles[_id] = style;
        emit NewMapStyleAdded(_id, _maxMint, _totalMint, _metaUrl);
    }
    
    function getBalanceThis() view public returns(uint){
        return address(this).balance;
    }

    function withdraw() public onlyOwner returns(bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }
    
    /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

/**
 * @title BLVD Map Style
 * MapStyle - a contract for ownership of limited edition digital collectible map styles
 * Customize in-app experiences in BULVRD app offerings https://bulvrdapp.com/#app
 */
contract MapStyle is TradeableERC721Token {
  constructor(address _proxyRegistryAddress) TradeableERC721Token("BLVD Map Style 2.0", "BLVDM", _proxyRegistryAddress) public {  }
}