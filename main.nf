// ******************* Start Helpers ********************
params.test
def withTest = { task -> { sc, tsc = "test_${task.process}" ->
    def out = sc.trim()
    if (params.test) {
      return out + "\n" + tsc.trim()
    }
    out
  }
}

// ******************** Start Params *********************
params.user = 'test1'

params.numSimulatedContentA = 1 // number of jobs
params.numSimulatedContentB = 2
params.numSimulatedContentC = 3

params.itersA = 5 // seconds
params.itersB = 5 
params.itersC = 5 

params.filesGlob = '/glob/for/example/*'
params.filePath = '/path/for/example'

// ******************** End Params *********************


// ******************* Start Workflow ********************
ContentsA = Channel.from(*(1..params.numSimulatedContentA))
ContentsB = Channel.from(*(1..params.numSimulatedContentB))
ContentsC = Channel.from(*(1..params.numSimulatedContentC))

process A {

  input:
  val contentId from ContentsA

  output:
  set contentId, 'a.out' into DependsOnA

  shell:
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersA} 
    echo "!{contentIds}" > a.out
    '''
  )
}

// Channel.fromPath(params.filesGlob).println()
// println(file(params.filePath).text)

// process C {

// }

// process dependsOnA {

// }

// process dependsOnB {

// }

// process dependsOnBothAandB {

// }

// process softlinkOnA {

// }

// process hardlinkOnB {

// }

// process publishBothAandB {

// }

// process mixDepADepBandDepBoth {

// }


// ******************* End Workflow ********************