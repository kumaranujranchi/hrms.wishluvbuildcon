import serverless from "serverless-http";
import { app, setupApp } from "../../server/index";

// Helper to ensure routes are registered only once
let appHandler: any;

export const handler = async (event: any, context: any) => {
  if (!appHandler) {
    // Initialize the app (register routes)
    // We wait for the setup to complete before creating the serverless handler
    await setupApp();
    appHandler = serverless(app);
  }
  return appHandler(event, context);
};
