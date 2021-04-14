import { IEmulation } from "./emulation.interface";
import Network from "../network";
import Accounts from "../accounts";
import _ from "lodash";

class NativeTokensTransferEmulation implements IEmulation {
  constructor(
    private readonly config,
    private readonly network: Network,
    private readonly account: Accounts
  ) {}

  public async run(): Promise<void> {
    for (let i = 1; i <= this.config.amount; i++) {
      console.log(`Running ${i} native token transfer...\n`);
      // const destination = await this.account.generateSrAccount();
      const destination = {ss58Address: "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"};
      const transferAmount = _.random(
        this.config.tokens_range[0],
        this.config.tokens_range[1]
      );
      const sender = this.account.rootAccount;
      const transfer = await this.network.transfer(
        sender,
        destination.ss58Address,
        transferAmount.toString()
      );
      const balance = await this.network.getBalance(destination.ss58Address);
      console.log(`Balance of ${destination.ss58Address} is ${balance}`);
    }
  }
}

export default NativeTokensTransferEmulation;
