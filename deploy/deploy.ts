import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const name = "ConfidentialToken";
  const symbol = "CFT";

  const deployed = await deploy("ConfidentialToken", {
    from: deployer,
    args: [name, symbol],
    log: true,
  });

  console.log(`ConfidentialToken contract deployed at: ${deployed.address}`);

  const deployedUsdc = await deploy("USDC", {
    from: deployer,
    args: [],
    log: true,
  });

  console.log(`USDC contract deployed at: ${deployedUsdc.address}`);

  const deployedWrapper = await deploy("ConfidentialERC20Wrapper", {
    from: deployer,
    args: [deployedUsdc.address],
    log: true,
  });

  console.log(`ConfidentialERC20Wrapper contract deployed at: ${deployedWrapper.address}`);
};

export default func;
func.id = "deploy_confidentialERC20";
func.tags = ["ConfidentialToken"];
