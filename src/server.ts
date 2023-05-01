import { ApolloServer } from "@apollo/server";
import { startServerAndCreateLambdaHandler, handlers } from "@as-integrations/aws-lambda";

const typeDefs = `#graphql
	type Query {
		hello: String
	}
`;

const resolvers = {
	Query: {
		hello: () => "world",
	},
};

const server = new ApolloServer({
	typeDefs,
	resolvers
});

export default startServerAndCreateLambdaHandler(
	server,
	handlers.createAPIGatewayProxyEventV2RequestHandler(),
);
