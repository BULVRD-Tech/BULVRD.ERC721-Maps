pragma solidity ^0.5.9;

import "./Mapv2.sol";
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol';

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various 
 * ways of minting.
 */
interface Factory {
  /**
   * Returns the name of this factory.
   */
  function name() external view returns (string memory);

  /**
   * Returns the symbol for this factory.
   */
  function symbol() external view returns (string memory);

  /**
   * Number of options the factory supports.
   */
  function numOptions() external view returns (uint256);

  /**
   * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
   * restrict a total supply per option ID (or overall).
   */
  function canMint(uint256 _optionId) external view returns (bool);

  /**
   * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
   * same structure as the ERC721 metadata.
   */
  function tokenURI(uint256 _optionId) external view returns (string memory);

  /**
   * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
   */
  function supportsFactoryInterface() external view returns (bool);

  /**
    * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be 
    * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
    * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
    * @param _optionId the option id
    * @param _toAddress address of the future owner of the asset(s)
    */
  function mint(uint256 _optionId, address _toAddress) external;
}

contract MapFactory is Factory, Ownable {

//Change for deployment to mainnet
  address public proxyRegistryAddress = address(0xF57B2c51dED3A29e6891aba85459d600256Cf317);
  address public nftAddress = address(0x165bfCace1e65f9085B4697675408731f29c3CfA);
  
  //initial items
  uint256 NUM_OPTIONS = 6;

  constructor() public {

  }

  function name() external view returns (string memory) {
    return "BLVD Map Item Sale";
  }

  function symbol() external view returns (string memory) {
    return "BMF";
  }

  function supportsFactoryInterface() public view returns (bool) {
    return true;
  }

  function numOptions() public view returns (uint256) {
    return NUM_OPTIONS;
  }
  
    function updateNumOptions(uint256 _newOptions) public onlyOwner {
        NUM_OPTIONS = _newOptions;
    }
    
    function updateProxyAddress(address _proxy) public onlyOwner {
        proxyRegistryAddress = _proxy;
    }
    
    function updateNftAddress(address _nft) public onlyOwner {
        nftAddress = _nft;
    }
  
  function mint(uint256 _optionId, address _toAddress) public {
    // Must be sent from the owner proxy or owner.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    assert(address(proxyRegistry.proxies(owner())) == msg.sender || owner() == msg.sender);
    require(canMint(_optionId));

    MapStyle(nftAddress).mintTo(_toAddress, _optionId);
  }

  function canMint(uint256 _optionId) public view returns (bool) {
    if (_optionId >= NUM_OPTIONS) {
      return false;
    }
    
    //Checks if max mint for each map style has been reached
    if(MapStyle(nftAddress).maxMintForStyle(_optionId) < MapStyle(nftAddress).totalMintForStyle(_optionId)){
        return true;
    }
    return false;
  }
  
  function tokenURI(uint256 _optionId) external view returns (string memory) {
    return MapStyle(nftAddress).tokenURIForStyle(_optionId);
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use transferFrom so the frontend doesn't have to worry about different method names.
   */
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    mint(_tokenId, _to);
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
   */
  function isApprovedForAll(address _owner, address _operator) public view
    returns (bool){
    if (owner() == _owner && _owner == _operator) {
      return true;
    }

    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return false;
  }

  /**
   * Hack to get things to work automatically on OpenSea.
   * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
   */
  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return owner();
  }
}