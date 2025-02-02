apiVersion: batch/v1
kind: Job
metadata:
  name: openstreetmap-import
spec:
  template:
    metadata:
      name: openstreetmap-import
    spec:
      initContainers:
      - name: setup
        image: 599239948849.dkr.ecr.ap-southeast-2.amazonaws.com/busybox:latest
        command: ["/bin/sh","-c"]
        # args: ["mkdir -p /data/openstreetmap && chown 1000:1000 /data/openstreetmap"]
        args: ["mkdir -p /data/openstreetmap"]
        volumeMounts:
        - name: data-volume
          mountPath: /data
      - name: download
        image: 599239948849.dkr.ecr.ap-southeast-2.amazonaws.com/pelias/openstreetmap:{{ .Values.openstreetmapDockerTag | default "latest"}}
        command: ["./bin/download"]
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
          - name: data-volume
            mountPath: /data
        env:
          - name: PELIAS_CONFIG
            value: "/etc/config/pelias.json"
        resources:
          limits:
            memory: 1Gi
            cpu: 2
          requests:
            memory: 256Mi
            cpu: 0.5
      containers:
      - name: openstreetmap-import-container
        image: 599239948849.dkr.ecr.ap-southeast-2.amazonaws.com/pelias/openstreetmap:{{ .Values.openstreetmapDockerTag | default "latest"}}
        command: ["./bin/start"]
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
          - name: data-volume
            mountPath: /data
        env:
          - name: PELIAS_CONFIG
            value: "/etc/config/pelias.json"
        resources:
          limits:
            memory: 8Gi
            cpu: 3
          requests:
            memory: 4Gi
            cpu: 1.5
      restartPolicy: OnFailure
      volumes:
        - name: config-volume
          configMap:
            name: pelias-json-configmap
            items:
              - key: pelias.json
                path: pelias.json
        - name: data-volume
          persistentVolumeClaim:
            claimName: pelias-build-pvc
