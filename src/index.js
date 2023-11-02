exports.handler = async (event, context) => {
  const response = {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message: "Hola from Lambda 0" }),
  };

  return response;
};