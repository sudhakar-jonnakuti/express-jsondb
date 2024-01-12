import { cleanEnv, port } from "envalid";

const appEnvValidate = () => {
  cleanEnv(process.env, {
    APP_PORT: port()
  });
};

export { appEnvValidate };
