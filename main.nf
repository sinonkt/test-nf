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

params.itersA = 5 // seconds
params.itersB = 5 
params.itersC = 5 

params.itersDependsOnC = 1
params.itersDependsOnBothAandB = 1

params.filesGlob = '/glob/for/example/*'
params.filePath = '/path/for/example'

params.publishDir = '/path/to/publishDir'

// ******************** End Params *********************


// ******************* Start Workflow ********************
ContentsA = Channel.from(*(1..params.numSimulatedContentA))
ContentsB = Channel.from(*(1..params.numSimulatedContentB))
Channel
  .fromPath(params.filesGlob)
  .splitText() { it.trim() }
  .flatten()
  .set { ContentsC }

process A {

  input:
  val contentId from ContentsA

  output:
  set contentId, 'a.out' into ResultA

  shell:
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersA} 
    echo "!{contentId}" > a.out
    ''',
    '''
    test_A a.out 
    '''
  )
}

process B {

  input:
  val contentId from ContentsB

  output:
  set contentId, 'b.out' into ResultB

  shell:
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersB} 
    echo "!{contentId}" > b.out
    ''',
    '''
    test_B b.out 
    '''
  )
}
process C {

  input:
  val contentId from ContentsC

  output:
  set contentId, 'c.out' into DependsOnC

  shell:
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersC} 
    echo "!{contentId}" > c.out
    ''',
    '''
    test_C c.out 
    '''
  )
}

ResultAandB = ResultA.mix(ResultB).groupTuple()

process DependsOnBothAandB {

  input:
  set contentId, results from ResultAandB

  output:
  set contentId, 'mixed.out' into MixedResult

  shell:
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersDependsOnBothAandB}
    echo "##mixed_19" > mixed.out
    ''',
    '''
    test_dependsOnBothAandB mixed.out !{results.join(' ')}
    '''
  )

}

process DependsOnC {

  input:
  set contentId, 'c.out' from DependsOnC

  output:
  set contentId, "${contentId}.txt" into ResultC

  shell:
  filesByChar = contentId.toCharArray().collect{ "${it}.txt" }.join(' ')
  withTest(task)(
    '''
    simulate_job !{task.process} !{contentId} !{params.itersDependsOnC} 
    touch !{contentId}.txt
    for char in !{contentId.toCharArray().join(' ')}
    do
      touch $char.txt
    done
    ''',
    '''
    test_dependsOnA !{contentId}.txt !{filesByChar}
    '''
  )
}

process FinalMerge {

  publishDir "${params.publishDir}/final/${finalId}", mode: 'copy', overwrite: true

  input:
  set mixedId, 'mixed.out', cId, "${cId}.txt" from MixedResult.merge(ResultC)
  
  output:
  set finalId, "final.out" into FinalResult

  shell:
  finalId="${mixedId}_$cId"
  withTest(task)(
    '''
    simulate_job !{task.process} !{finalId} 1
    cat mixed.out !{cId}.txt > final.out
    ''',
    '''
    test_FinalMerge final.out
    '''
  )
}



// ******************* End Workflow ********************