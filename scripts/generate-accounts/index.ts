import * as fs from 'fs';
import { Keyring } from "@polkadot/api";
import { mnemonicGenerate, cryptoWaitReady } from "@polkadot/util-crypto";
import { u8aToHex } from '@polkadot/util';
import { KeyringPair } from '@polkadot/keyring/types';

class Accounts {
  public async generate() {
    if (!fs.existsSync('accounts')) {
      fs.mkdirSync('accounts');
    }
    const dir = 'accounts/all';
    if (fs.existsSync(dir)) {
      fs.rmdirSync(dir, { recursive: true });
    }
    fs.mkdirSync(dir);

    await cryptoWaitReady();

    const rootAccount = await this.generateRootAccount();
    console.log('\n');

    const sudoAccount = await this.generateSudoAccount();
    console.log('\n');

    const validatorGenesisAccounts = await this.generateGenesisValidatorsAccounts(2);
    console.log('\n');

    const validatorAccounts = await this.generateValidatorsAccounts(3);
    console.log('\n');

    this.generateFileWithPublicKeys(rootAccount, sudoAccount, validatorGenesisAccounts);
  }

  private async generateRootAccount() {
    console.log('Generating Root account...');

    const account = await this.generateSrAccount();
    this.writeKeyToFile(`root`, JSON.stringify(account));
    console.log(`Root account has been written to the 'root' file`);

    return account;
  }

  private async generateSudoAccount() {
    console.log('Generating Sudo account...');

    const account = await this.generateSrAccount();
    this.writeKeyToFile(`sudo`, JSON.stringify(account));
    console.log(`Sudo account has been written to the 'sudo' file`);

    return account;
  }

  private async generateGenesisValidatorsAccounts(number: number) {
    const accounts = [];

    for (let i = 1; i <= number; i++) {
      const validatorStashAccounts = await this.generateGenesisValidatorAccounts(i, 'stash');
      const validatorControllerAccounts = await this.generateGenesisValidatorAccounts(i, 'controller');
      accounts.push({stash: validatorStashAccounts, controller: validatorControllerAccounts});
    }

    return accounts;
  }

  private async generateValidatorsAccounts(number: number) {
    const accounts = [];

    for (let i = 1; i <= number; i++) {
      const account = await this.generateValidatorAccounts(i);
      accounts.push(account);
    }

    return accounts;
  }

  private async generateGenesisValidatorAccounts(id: number, name: string) {
    console.log(`Generating Validator genesis accounts...`);

    const srAccount = await this.generateSrAccount();
    const srFilename = `validator-${id}-${name}-sr`;
    this.writeKeyToFile(srFilename, JSON.stringify(srAccount));
    console.log(`Validator ${id} ${name} sr account has been written to the '${srFilename}' file`);

    const edFilename = `validator-${id}-${name}-ed`;
    const edAccount = await this.generateEdAccount(srAccount.mnemonic);
    this.writeKeyToFile(edFilename, JSON.stringify(edAccount));
    console.log(`Validator ${id} ${name} ed account has been written to the '${edFilename}' file`);

    return {srAccount, edAccount};
  }

  private async generateValidatorAccounts(id) {
    console.log(`Generating Validator accounts...`);

    const stashAccount = await this.generateSrAccount();
    const stashFilename = `validator-${id}-stash`;
    this.writeKeyToFile(stashFilename, JSON.stringify(stashAccount));
    console.log(`Validator ${id} stash account has been written to the '${stashFilename}' file`);

    const controllerFilename = `validator-${id}-controller`;
    const controllerAccount = await this.generateSrAccount();
    this.writeKeyToFile(controllerFilename, JSON.stringify(controllerAccount));
    console.log(`Validator ${id} controller account has been written to the '${controllerFilename}' file`);

    return {stashAccount, controllerAccount};
  }

  public generateFileWithPublicKeys(rootAccount: any, sudoAccount: any, validatorGenesisAccounts) {
    const filename = 'accounts/public';

    if (fs.existsSync(filename)) {
      fs.writeFileSync(filename, '');
    }

    const rootAccountContent = `Root account public key is '${rootAccount.ss58Address}'\n`;
    fs.appendFileSync(filename, rootAccountContent);

    const sudoAccountContent = `Sudo account public key is '${sudoAccount.ss58Address}'\n`;
    fs.appendFileSync(filename, sudoAccountContent);

    let genesisValidatorsContent = `Genesis validators\n`;
    for (let i = 0; i < validatorGenesisAccounts.length; i++) {
      genesisValidatorsContent += `Validator ${i+1} stash sr account public key is '${validatorGenesisAccounts[i].stash.srAccount.ss58Address}'\n`;
      genesisValidatorsContent += `Validator ${i+1} stash ed account public key is '${validatorGenesisAccounts[i].stash.edAccount.ss58Address}'\n`;
      genesisValidatorsContent += `Validator ${i+1} controller sr account public key is '${validatorGenesisAccounts[i].controller.srAccount.ss58Address}'\n`;
      genesisValidatorsContent += `Validator ${i+1} controller ed account public key is '${validatorGenesisAccounts[i].controller.edAccount.ss58Address}'\n`;
    }
    fs.appendFileSync(filename, genesisValidatorsContent);
  }

  private async generateSrAccount() {
    const keyring = new Keyring({ type: "sr25519"});
    const mnemonic = mnemonicGenerate(12);
    const pair = keyring.addFromUri(mnemonic, {});

    return this.extractKeys(mnemonic, pair);
  }

  private async generateEdAccount(mnemonic: string) {
    const keyring = new Keyring({ type: "ed25519"});
    const pair = keyring.addFromUri(mnemonic, {});

    return this.extractKeys(mnemonic, pair);
  }

  private extractKeys(mnemonic: string, pair: KeyringPair) {

    return {mnemonic, publicKey: u8aToHex(pair.publicKey), accountId: u8aToHex(pair.publicKey), ss58Address: pair.address};
  }

  private getValueFromOutputByKey(output: string, key: string, spaces: number, length: number): string {
    const index = output.indexOf(key) + key.length + spaces;
    const value = output.substring(index, index + length);

    return value;
  }

  private writeKeyToFile(filename: string, content: string) {
    fs.writeFileSync(`accounts/all/${filename}`, content);
  }
}

async function main() {
  const accounts = new Accounts();
  await accounts.generate();
}

main()
  .catch(console.error)
  .finally(() => process.exit());