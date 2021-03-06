# Description
#   A hubot brain built on DynamoDB
#
# Configuration:
# HUBOT_AWS_REGION - Default to us-east-2 if not set
# HUBOT_DYNAMO_ENDPOINT - Endpoint to connect to for dynamodb
# HUBOT_BRAIN_DYNAMO_TABLE - DynamoDB table, default hubotbrain
# HUBOT_DYNAMO_NAME - Brain entry in table, default is our robot name
# HUBOT_AWS_ACCESS_KEY_ID - AWS Credentials, default to instance IAM
# HUBOT_AWS_SECRET_ACCESS_KEY - AWS Credentials, default to instance IAM
#
# Commands:
#   hubot brainscan - Check to make sure our brain is working
#
# Notes:
#   This bot requires the DynamoDB table to exist prior to running.
#   See Readme for CFT snippet to create table
#
# Author:
#   Nitehawk <nitehawk@nitespace.co>

AWS = require 'aws-sdk'

module.exports = (robot) ->
  config = {}
  params = {}
  creds = {}

  config.region = process.env.HUBOT_AWS_REGION or 'us-east-2'
  config.endpoint = process.env.HUBOT_DYNAMO_ENDPOINT or undefined
  params.TableName = process.env.HUBOT_BRAIN_DYNAMO_TABLE or 'hubotbrain'
  params.Key = { botname: process.env.HUBOT_BRAIN_DYNAMO_NAME or robot.name }
  creds.access = process.env.HUBOT_AWS_ACCESS_KEY_ID or undefined
  creds.secret = process.env.HUBOT_AWS_SECRET_ACCESS_KEY or undefined
  saveBrainInterval = process.env.HOBOT_SAVE_BRAIN_INTERVAL or 5


  if creds.access and creds.secret
    config.accessKeyId = creds.access
    config.secretAccessKey = creds.secret

  AWS.config.update config

  doc = new AWS.DynamoDB.DocumentClient({convertEmptyValues: true,})
  saveBrain = (data = {}) ->
    brain = {TableName: params.TableName, Item: data}
    brain.Item.botname = params.Key.botname
    doc.put brain, (err, res) ->
      if err
        throw err

  loadBrain = (params) ->
    robot.brain.setAutoSave false

    doc.get params, (err, data) ->
      if err
        throw err
      else if data.Item.users
        robot.logger.info "hubot-dynamodb-brain: Data for #{params.Key.botname} retrieved from Dynamo"
        robot.brain.mergeData data.Item
      else
        robot.logger.info "hubot-dynamodb-brain: Initializing new brain for #{params.Key.botname}"
        robot.brain.mergeData {}

    robot.brain.setAutoSave true

  loadBrain params

  robot.brain.resetSaveInterval saveBrainInterval

  robot.brain.on 'save', (data = {}) ->
    saveBrain data

  robot.respond /brainscan/, (res) ->
    # Create a random key, save it to dynamo, retrieve it and compare the result.
    brainkey = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    robot.logger.info "hubot-dynamodb-brain: BRAINSCAN: Saving #{brainkey} to brainkey"
    robot.brain.set 'brainkey', brainkey
    keycheck = robot.brain.get('brainkey')
    robot.logger.info "hubot-dynamodb-brain: BRAINSCAN: Retrieved #{keycheck} from brain"
    if keycheck == brainkey
      res.reply "My brain is called '#{params.Key.botname}' and it's doing great!"

    else
      res.reply "I forgot already! :("

